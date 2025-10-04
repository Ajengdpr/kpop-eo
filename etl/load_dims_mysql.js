import 'dotenv/config';
import dayjs from 'dayjs';
import {oltp, dw, withTx} from './db.js';

async function upsert(conn, table, natCol, natVal, cols){
  const keys = Object.keys(cols);
  const vals = Object.values(cols);
  const sql  = `INSERT INTO ${table} (${natCol},${keys.join(',')})
                VALUES (?,${keys.map(()=>'?').join(',')})
                ON DUPLICATE KEY UPDATE ${keys.map(k=>`${k}=VALUES(${k})`).join(',')}`;
  await conn.execute(sql, [natVal, ...vals]);
}

async function loadCore(){
  await withTx(dw, async c=>{
    const [ev] = await oltp.execute(`
      SELECT e.event_id, e.title, e.event_date, e.start_time, v.name AS venue_name, v.city
      FROM events e JOIN venues v ON v.venue_id=e.venue_id`);
    for (const r of ev){
      await upsert(c,'dim_event','event_id',r.event_id,{
        title:r.title, event_date:r.event_date, start_time:r.start_time,
        venue_name:r.venue_name, city:r.city
      });
    }

    const defs = [
      ['venues','venue_id','dim_venue', r=>({name:r.name, city:r.city, country:r.country, capacity:r.capacity})],
      ['ticket_types','ticket_type_id','dim_ticket_type', r=>({name:r.name, base_price:r.price})],
      ['seats','seat_id','dim_seat', r=>({section:r.section, row_label:r.row_label, seat_number:r.seat_number})],
      ['customers','customer_id','dim_customer', r=>({full_name:r.full_name, email:r.email})],
      ['channels','channel_id','dim_channel', r=>({name:r.name})],
      ['artists','artist_id','dim_artist', r=>({stage_name:r.stage_name})]
    ];

    for (const [src,id,dim,map] of defs){
      const [rows] = await oltp.execute(`SELECT * FROM ${src}`);
      for (const r of rows){
        await upsert(c, dim, id, r[id], map(r));
      }
    }

    const [ea] = await oltp.execute(`
      SELECT ea.event_id, ea.artist_id,
        1.0 / NULLIF((SELECT COUNT(*) FROM event_artists x WHERE x.event_id=ea.event_id),0) AS weight
      FROM event_artists ea`);
    for (const r of ea){
      const [[de]] = await c.execute('SELECT event_key FROM dim_event WHERE event_id=?',[r.event_id]);
      const [[da]] = await c.execute('SELECT artist_key FROM dim_artist WHERE artist_id=?',[r.artist_id]);
      if (de && da){
        await c.execute(
          `INSERT INTO bridge_event_artist(event_key,artist_key,weight)
           VALUES (?,?,?)
           ON DUPLICATE KEY UPDATE weight=VALUES(weight)`,
          [de.event_key, da.artist_key, r.weight]
        );
      }
    }
  });
}

async function loadDateTime(){
  await withTx(dw, async c=>{
    const [[rng]] = await oltp.execute(`SELECT MIN(order_datetime) AS min_d, MAX(order_datetime) AS max_d FROM orders`);

    const minStart = (rng && rng.min_d) ? dayjs(rng.min_d) : dayjs();
    const maxEnd   = (rng && rng.max_d) ? dayjs(rng.max_d) : dayjs();

    let d = minStart.subtract(120,'day');
    const end = maxEnd.add(120,'day');

    while (!d.isAfter(end,'day')){
      const dk = Number(d.format('YYYYMMDD'));
      const isWeekend = (d.day() === 0 || d.day() === 6) ? 1 : 0; 

      await c.execute(
        `INSERT IGNORE INTO dim_date(date_key,date_value,day,month,year,quarter,day_name,is_weekend)
         VALUES (?,?,?,?,?,?,?,?)`,
        [dk, d.format('YYYY-MM-DD'), +d.format('D'), +d.format('M'), +d.format('YYYY'),
         +d.format('Q'), d.format('ddd'), isWeekend]
      );
      d = d.add(1,'day');
    }

    for (let h=0; h<24; h++){
      for (let m=0; m<60; m++){
        const tk = h*100 + m;
        await c.execute(`INSERT IGNORE INTO dim_time(time_key,hour,minute) VALUES (?,?,?)`, [tk,h,m]);
      }
    }
  });
}

await loadCore();
await loadDateTime();
console.log('dims OK');
await oltp.end();   
await dw.end(); 