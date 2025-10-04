
import 'dotenv/config';
import dayjs from 'dayjs';
import {oltp, dw, withTx} from './db.js';

const dkey = d => Number(dayjs(d).format('YYYYMMDD'));
const tkey = d => Number(dayjs(d).format('HHmm'));

async function keyOf(conn, dim, natCol, natVal, ret){
  const [rows] = await conn.execute(`SELECT ${ret} FROM ${dim} WHERE ${natCol}=?`, [natVal]);
  return rows.length ? rows[0][ret] : null;
}

async function loadSales(){
  await withTx(dw, async c=>{
    const [rows] = await oltp.execute(`
      SELECT oi.order_item_id, oi.unit_price, oi.discount,
             o.order_datetime, o.channel_id, o.event_id,
             t.ticket_id, t.ticket_type_id, t.seat_id,
             o.customer_id, v.venue_id
      FROM order_items oi
      JOIN orders o  ON o.order_id = oi.order_id AND o.status='PAID'
      JOIN tickets t ON t.ticket_id = oi.ticket_id
      JOIN events  e ON e.event_id = o.event_id
      JOIN venues  v ON v.venue_id = e.venue_id`);
    for (const r of rows){
      const event_key = await keyOf(c,'dim_event','event_id',r.event_id,'event_key');
      const venue_key = await keyOf(c,'dim_venue','venue_id',r.venue_id,'venue_key');
      const type_key  = await keyOf(c,'dim_ticket_type','ticket_type_id',r.ticket_type_id,'ticket_type_key');
      const seat_key  = r.seat_id ? await keyOf(c,'dim_seat','seat_id',r.seat_id,'seat_key') : null;
      const cust_key  = await keyOf(c,'dim_customer','customer_id',r.customer_id,'customer_key');
      const chan_key  = await keyOf(c,'dim_channel','channel_id',r.channel_id,'channel_key');
      await c.execute(
        `INSERT INTO fact_ticket_sales(
          order_item_id,event_key,venue_key,date_key,time_key,
          ticket_type_key,seat_key,customer_key,channel_key,
          qty,gross_amount,discount,net_amount
        ) VALUES (?,?,?,?,?,?,?,?,?,1,?,?,?)
        ON DUPLICATE KEY UPDATE order_item_id=order_item_id`,
        [r.order_item_id,event_key,venue_key,dkey(r.order_datetime),tkey(r.order_datetime),
         type_key,seat_key,cust_key,chan_key,
         r.unit_price,r.discount,Number(r.unit_price)-Number(r.discount)]
      );
    }
  });
}

async function loadAttendance(){
  await withTx(dw, async c=>{
    const [rows] = await oltp.execute(`
      SELECT ch.checkin_id, ch.scan_datetime, t.ticket_type_id, t.seat_id, e.event_id
      FROM checkins ch
      JOIN tickets t ON t.ticket_id = ch.ticket_id
      JOIN events  e ON e.event_id = t.event_id`);
    for (const r of rows){
      const event_key = await keyOf(c,'dim_event','event_id',r.event_id,'event_key');
      const type_key  = await keyOf(c,'dim_ticket_type','ticket_type_id',r.ticket_type_id,'ticket_type_key');
      const seat_key  = r.seat_id ? await keyOf(c,'dim_seat','seat_id',r.seat_id,'seat_key') : null;
      await c.execute(
        `INSERT INTO fact_attendance(checkin_id,event_key,date_key,time_key,ticket_type_key,seat_key,attended)
         VALUES (?,?,?,?,?,?,1)
         ON DUPLICATE KEY UPDATE checkin_id=checkin_id`,
        [r.checkin_id,event_key,dkey(r.scan_datetime),tkey(r.scan_datetime),type_key,seat_key]
      );
    }
  });
}

await loadSales();
await loadAttendance();
console.log('facts OK');
await oltp.end();   
await dw.end();     