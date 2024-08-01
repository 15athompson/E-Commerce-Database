ALTER TABLE reviews
ADD COLUMN quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
ADD COLUMN value_rating INTEGER CHECK (value_rating BETWEEN 1 AND 5),
ADD COLUMN helpful_votes INTEGER DEFAULT 0;