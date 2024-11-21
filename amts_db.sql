CREATE DATABASE IF NOT EXISTS amts_db;
USE amts_db;

-- Admin Table
CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    role_name VARCHAR(25) NOT NULL,
    password VARCHAR(60) NOT NULL -- hashed passwords - generated in backend
);

-- Station Table
CREATE TABLE station (
    station_id VARCHAR(15) PRIMARY KEY,
    station_name VARCHAR(45) UNIQUE NOT NULL,
    location VARCHAR(45)
);

-- Train Table
CREATE TABLE train (
    train_no VARCHAR(5) PRIMARY KEY,
    train_name VARCHAR(45) NOT NULL,
    src_station VARCHAR(15) NOT NULL,  
    dest_station VARCHAR(15) NOT NULL, 
    duration INT NOT NULL,
    capacity INT NOT NULL,
    FOREIGN KEY (src_station) REFERENCES station(station_id),
    FOREIGN KEY (dest_station) REFERENCES station(station_id)
);

-- Tickets Table
CREATE TABLE tickets (
    ticket_id VARCHAR(50) PRIMARY KEY,
    passenger_name VARCHAR(60) NOT NULL,
    train_no VARCHAR(5),
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    price FLOAT,
    FOREIGN KEY (train_no) REFERENCES train(train_no)
);

-- Schedules Table -- for a passenger, its only visible as a table. for admins - able to change the frequency 
CREATE TABLE schedules (
    schedule_id VARCHAR(5) PRIMARY KEY,
    train_no VARCHAR(5) NOT NULL,
    src_station VARCHAR(15) NOT NULL,  
    dest_station VARCHAR(15) NOT NULL, 
    arrival_time TIME NOT NULL,
    departure_time TIME NOT NULL,
    frequency INT NOT NULL,
    capacity INT NOT NULL,
    FOREIGN KEY (train_no) REFERENCES train(train_no),
    FOREIGN KEY (src_station) REFERENCES station(station_id),
    FOREIGN KEY (dest_station) REFERENCES station(station_id)
);

-- Ticket Log Table - only visble to admins
CREATE TABLE ticket_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id VARCHAR(5),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(20),
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id)
);

-- data in station
INSERT INTO station (station_id, station_name, location)
VALUES
('Kadapa', 'Kadapa', 'Kadapa City'),
('Jammalamadugu', 'Jammalamadugu', 'Jammalamadugu Town');

-- data in 3NF
INSERT INTO train (train_no, train_name, src_station, dest_station, duration, capacity) 
VALUES
('T1001', 'Kadapa Express', 'Kadapa', 'Jammalamadugu', 30, 150),
('T1002', 'Jammalamadugu Fast', 'Jammalamadugu', 'Kadapa', 30, 140),
('T1003', 'Kadapa Local', 'Kadapa', 'Jammalamadugu', 45, 100),
('T1004', 'Jammalamadugu Superfast', 'Jammalamadugu', 'Kadapa', 30, 200),
('T1005', 'Kadapa- Jammalamadugu Special', 'Kadapa', 'Jammalamadugu', 25, 180),
('T1006', 'Jammalamadugu Shuttle', 'Jammalamadugu', 'Kadapa', 35, 120);

INSERT INTO schedules (schedule_id, train_no, src_station, dest_station, arrival_time, departure_time, frequency, capacity) 
VALUES
('S1001', 'T1001', 'Kadapa', 'Jammalamadugu', '08:00', '08:30', 3, 50), 
('S1002', 'T1002', 'Jammalamadugu', 'Kadapa', '09:00', '09:30', 2, 100),
('S1003', 'T1003', 'Kadapa', 'Jammalamadugu', '10:15', '11:00', 1, 75),
('S1004', 'T1004', 'Jammalamadugu', 'Kadapa', '11:30', '12:00', 4, 55),
('S1005', 'T1005', 'Kadapa', 'Jammalamadugu', '13:00', '13:25', 5, 100),
('S1006', 'T1006', 'Jammalamadugu', 'Kadapa', '14:30', '15:05', 6, 60);


INSERT INTO admin (email, role_name, password) VALUES ('giridhar@gmail.com','admin','rich');

-- Trigger to insert log after new ticket is added
DELIMITER //
CREATE TRIGGER after_ticket_insert
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO ticket_log (ticket_id, action) VALUES (NEW.ticket_id, 'Ticket Created');
END //
DELIMITER ;

-- Stored Procedure -- to create a ticket
DELIMITER //

CREATE PROCEDURE create_ticket(
    IN p_passenger_name VARCHAR(60),
    IN p_train_no VARCHAR(5),
    IN p_price FLOAT,
    OUT p_ticket_id VARCHAR(50)  -- OUT parameter to return the ticket_id
)
BEGIN
    -- Generate a unique ticket ID
    SET p_ticket_id = CONCAT(
        FLOOR(RAND() * 10000), 
        CHAR(FLOOR(65 + RAND() * 26))  
    );

    -- Insert the new ticket into the tickets table
    INSERT INTO tickets (ticket_id, passenger_name, train_no, price)
    VALUES (p_ticket_id, p_passenger_name, p_train_no, p_price);
    
    UPDATE schedules
	SET capacity = CASE WHEN capacity > 0 THEN capacity - 1 ELSE 0 END
	WHERE train_no = p_train_no;

END //
DELIMITER ;
-- Nested query - to see the train with highest frequency
SELECT train_no, frequency
FROM schedules
WHERE frequency = (
                    SELECT MAX(frequency)
                    FROM schedules
                    WHERE src_station = 'Kadapa' AND dest_station = 'Jammalamadugu'
                );


-- Join query - used in view ticket
SELECT 
    t.*, 
    tr.src_station, 
    tr.dest_station
FROM 
    tickets t
JOIN 
    train tr 
ON 
    tr.train_no = t.train_no
WHERE 
    t.ticket_id = '<ticket_id>';


-- Aggregate query - to fetch each train revenue
SELECT train_no, COUNT(ticket_id) AS total_passengers, SUM(price) AS total_revenue
        FROM tickets
        GROUP BY train_no
        ORDER BY total_revenue DESC;
        
        
        
        


