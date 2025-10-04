
import mysql from 'mysql2/promise';
export const oltp = await mysql.createPool({ uri: process.env.OLTP_URL, waitForConnections:true });
export const dw   = await mysql.createPool({ uri: process.env.DW_URL,   waitForConnections:true });

export async function withTx(pool, fn){
  const conn = await pool.getConnection();
  try { await conn.beginTransaction(); await fn(conn); await conn.commit(); }
  catch(e){ await conn.rollback(); throw e; }
  finally{ conn.release(); }
}
