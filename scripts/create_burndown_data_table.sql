CREATE TABLE burndown_data (
    id MEDIUMINT NOT NULL AUTO_INCREMENT,
    query_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sprint VARCHAR(255),
    responsible VARCHAR(255),
    remaining_hours INT,
    PRIMARY KEY (id)
);
