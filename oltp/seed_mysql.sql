
INSERT INTO venues(name, city, country, capacity)
VALUES ('Istora Senayan', 'Jakarta', 'ID', 10000);

WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 10
)
INSERT INTO seats(venue_id, section, row_label, seat_number)
SELECT 1, 'A', '1', CAST(n AS CHAR) FROM seq;

INSERT INTO artists(stage_name) VALUES ('Eclipse'), ('Starlight');

INSERT INTO ticket_types(name, price) VALUES
('VIP', 2500000), ('CAT1', 1800000), ('GA', 1200000);

INSERT INTO events(code, title, venue_id, event_date, doors_time, start_time)
VALUES ('ECL-JKT-2025', 'Eclipse Jakarta Fanmeet', 1, '2025-10-28', '17:00:00', '19:00:00');

INSERT INTO event_artists(event_id, artist_id, slot_order) VALUES (1,1,1), (1,2,2);

INSERT INTO tickets(event_id, ticket_type_id, seat_id, status)
SELECT 1, CASE WHEN seat_id<=3 THEN 1 ELSE 2 END, seat_id, 'AVAILABLE'
FROM seats WHERE seat_id BETWEEN 1 AND 6;

INSERT INTO tickets(event_id, ticket_type_id, seat_id, status)
SELECT 1, 3, NULL, 'AVAILABLE' FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) x;

INSERT INTO channels(name) VALUES ('Web'), ('Booth'), ('Komunitas');

INSERT INTO customers(full_name, email, phone) VALUES
('Jennie Kim', 'jennie@example.com', '0812-0000-0001'),
('Kim Taehyung', 'tae@example.com', '0812-0000-0002');

INSERT INTO orders(customer_id, event_id, channel_id, order_datetime, status)
VALUES (1, 1, 1, NOW() - INTERVAL 10 DAY, 'PAID');
INSERT INTO order_items(order_id, ticket_id, unit_price, discount)
VALUES (1, (SELECT ticket_id FROM tickets WHERE event_id=1 AND seat_id=1), 2500000, 0);
UPDATE tickets SET status='SOLD' WHERE event_id=1 AND seat_id=1;
INSERT INTO payments(order_id, method, paid_amount, paid_datetime)
VALUES (1, 'CC', 2500000, NOW() - INTERVAL 10 DAY);

INSERT INTO orders(customer_id, event_id, channel_id, order_datetime, status)
VALUES (2, 1, 1, NOW() - INTERVAL 7 DAY, 'PAID');
INSERT INTO order_items(order_id, ticket_id, unit_price, discount)
VALUES (2, (SELECT ticket_id FROM tickets WHERE event_id=1 AND seat_id IS NULL LIMIT 1), 1200000, 0);
UPDATE tickets SET status='SOLD'
WHERE ticket_id = (SELECT ticket_id FROM order_items WHERE order_id=2);
INSERT INTO payments(order_id, method, paid_amount, paid_datetime)
VALUES (2, 'CC', 1200000, NOW() - INTERVAL 7 DAY);

INSERT INTO checkins(ticket_id, scan_datetime, gate)
VALUES ((SELECT ticket_id FROM order_items WHERE order_id=1), NOW() - INTERVAL 1 DAY, 'Gate A');
