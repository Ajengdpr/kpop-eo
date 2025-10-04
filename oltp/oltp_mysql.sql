
SET NAMES utf8mb4; SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS checkins, payments, order_items, orders, channels, tickets, ticket_types,
                     event_artists, artists, events, seats, venues, customers;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE venues(
  venue_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  city VARCHAR(100),
  country VARCHAR(50),
  capacity INT,
  INDEX(city)
) ENGINE=InnoDB;

CREATE TABLE seats(
  seat_id INT PRIMARY KEY AUTO_INCREMENT,
  venue_id INT NOT NULL,
  section VARCHAR(50),
  row_label VARCHAR(50),
  seat_number VARCHAR(50),
  UNIQUE KEY uq_seat (venue_id, section, row_label, seat_number),
  CONSTRAINT fk_seat_venue FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE events(
  event_id INT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(100) UNIQUE,
  title VARCHAR(255) NOT NULL,
  venue_id INT NOT NULL,
  event_date DATE NOT NULL,
  doors_time TIME,
  start_time TIME,
  CONSTRAINT fk_event_venue FOREIGN KEY (venue_id) REFERENCES venues(venue_id)
) ENGINE=InnoDB;

CREATE TABLE artists(
  artist_id INT PRIMARY KEY AUTO_INCREMENT,
  stage_name VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE event_artists(
  event_id INT NOT NULL,
  artist_id INT NOT NULL,
  slot_order INT,
  PRIMARY KEY (event_id, artist_id),
  CONSTRAINT fk_ea_event  FOREIGN KEY (event_id)  REFERENCES events(event_id)  ON DELETE CASCADE,
  CONSTRAINT fk_ea_artist FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ticket_types(
  ticket_type_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE tickets(
  ticket_id INT PRIMARY KEY AUTO_INCREMENT,
  event_id INT NOT NULL,
  ticket_type_id INT NOT NULL,
  seat_id INT NULL,
  status ENUM('AVAILABLE','RESERVED','SOLD','CANCELLED') NOT NULL DEFAULT 'AVAILABLE',
  UNIQUE KEY uq_ticket_seat (event_id, seat_id),
  CONSTRAINT fk_t_event  FOREIGN KEY (event_id)       REFERENCES events(event_id)       ON DELETE CASCADE,
  CONSTRAINT fk_t_type   FOREIGN KEY (ticket_type_id)  REFERENCES ticket_types(ticket_type_id),
  CONSTRAINT fk_t_seat   FOREIGN KEY (seat_id)         REFERENCES seats(seat_id)
) ENGINE=InnoDB;

CREATE TABLE customers(
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(200) NOT NULL,
  email VARCHAR(200) UNIQUE,
  phone VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE channels(
  channel_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE orders(
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  event_id INT NOT NULL,
  channel_id INT NULL,
  order_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('PENDING','PAID','CANCELLED') NOT NULL DEFAULT 'PENDING',
  INDEX idx_event_time (event_id, order_datetime),
  CONSTRAINT fk_o_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_o_event    FOREIGN KEY (event_id)    REFERENCES events(event_id),
  CONSTRAINT fk_o_channel  FOREIGN KEY (channel_id)  REFERENCES channels(channel_id)
) ENGINE=InnoDB;

CREATE TABLE order_items(
  order_item_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  ticket_id INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  discount DECIMAL(12,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_item_ticket (ticket_id),
  CONSTRAINT fk_oi_order  FOREIGN KEY (order_id)  REFERENCES orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_oi_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id)
) ENGINE=InnoDB;

CREATE TABLE payments(
  payment_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  method VARCHAR(50),
  paid_amount DECIMAL(12,2),
  paid_datetime DATETIME,
  CONSTRAINT fk_p_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE checkins(
  checkin_id INT PRIMARY KEY AUTO_INCREMENT,
  ticket_id INT NOT NULL,
  scan_datetime DATETIME NOT NULL,
  gate VARCHAR(50),
  UNIQUE KEY uq_checkin_ticket (ticket_id),
  CONSTRAINT fk_ci_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE
) ENGINE=InnoDB;
