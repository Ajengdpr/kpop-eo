
DROP TABLE IF EXISTS fact_attendance, fact_ticket_sales, bridge_event_artist,
                     dim_artist, dim_channel, dim_customer, dim_seat, dim_ticket_type,
                     dim_venue, dim_event, dim_time, dim_date;

CREATE TABLE dim_date(
  date_key INT PRIMARY KEY,
  date_value DATE NOT NULL,
  day INT, month INT, year INT, quarter INT,
  day_name VARCHAR(10),
  is_weekend TINYINT(1)
) ENGINE=InnoDB;

CREATE TABLE dim_time(
  time_key INT PRIMARY KEY,
  hour INT, minute INT
) ENGINE=InnoDB;

CREATE TABLE dim_event(
  event_key INT PRIMARY KEY AUTO_INCREMENT,
  event_id INT UNIQUE,
  title VARCHAR(255), city VARCHAR(100), venue_name VARCHAR(255),
  event_date DATE, start_time TIME
) ENGINE=InnoDB;

CREATE TABLE dim_venue(
  venue_key INT PRIMARY KEY AUTO_INCREMENT,
  venue_id INT UNIQUE,
  name VARCHAR(255), city VARCHAR(100), country VARCHAR(50), capacity INT
) ENGINE=InnoDB;

CREATE TABLE dim_ticket_type(
  ticket_type_key INT PRIMARY KEY AUTO_INCREMENT,
  ticket_type_id INT UNIQUE,
  name VARCHAR(100), base_price DECIMAL(12,2)
) ENGINE=InnoDB;

CREATE TABLE dim_seat(
  seat_key INT PRIMARY KEY AUTO_INCREMENT,
  seat_id INT UNIQUE,
  section VARCHAR(50), row_label VARCHAR(50), seat_number VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE dim_customer(
  customer_key INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT UNIQUE,
  full_name VARCHAR(200), email VARCHAR(200)
) ENGINE=InnoDB;

CREATE TABLE dim_channel(
  channel_key INT PRIMARY KEY AUTO_INCREMENT,
  channel_id INT UNIQUE,
  name VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE dim_artist(
  artist_key INT PRIMARY KEY AUTO_INCREMENT,
  artist_id INT UNIQUE,
  stage_name VARCHAR(150)
) ENGINE=InnoDB;

CREATE TABLE bridge_event_artist(
  event_key INT, artist_key INT, weight DECIMAL(5,4) DEFAULT 1.0,
  PRIMARY KEY(event_key, artist_key),
  FOREIGN KEY (event_key) REFERENCES dim_event(event_key),
  FOREIGN KEY (artist_key) REFERENCES dim_artist(artist_key)
) ENGINE=InnoDB;

CREATE TABLE fact_ticket_sales(
  ticket_sales_key BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_item_id INT UNIQUE,
  event_key INT, venue_key INT, date_key INT, time_key INT,
  ticket_type_key INT, seat_key INT, customer_key INT, channel_key INT,
  qty INT DEFAULT 1, gross_amount DECIMAL(12,2), discount DECIMAL(12,2), net_amount DECIMAL(12,2),
  INDEX idx_event_date (event_key, date_key),
  FOREIGN KEY (event_key) REFERENCES dim_event(event_key),
  FOREIGN KEY (venue_key) REFERENCES dim_venue(venue_key),
  FOREIGN KEY (date_key)  REFERENCES dim_date(date_key),
  FOREIGN KEY (time_key)  REFERENCES dim_time(time_key),
  FOREIGN KEY (ticket_type_key) REFERENCES dim_ticket_type(ticket_type_key),
  FOREIGN KEY (seat_key)  REFERENCES dim_seat(seat_key),
  FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
  FOREIGN KEY (channel_key)  REFERENCES dim_channel(channel_key)
) ENGINE=InnoDB;

CREATE TABLE fact_attendance(
  attendance_key BIGINT PRIMARY KEY AUTO_INCREMENT,
  checkin_id INT UNIQUE,
  event_key INT, date_key INT, time_key INT,
  ticket_type_key INT, seat_key INT, attended INT DEFAULT 1,
  INDEX idx_event_date2 (event_key, date_key),
  FOREIGN KEY (event_key) REFERENCES dim_event(event_key),
  FOREIGN KEY (date_key)  REFERENCES dim_date(date_key),
  FOREIGN KEY (time_key)  REFERENCES dim_time(time_key),
  FOREIGN KEY (ticket_type_key) REFERENCES dim_ticket_type(ticket_type_key),
  FOREIGN KEY (seat_key)  REFERENCES dim_seat(seat_key)
) ENGINE=InnoDB;
