# Use the official MySQL 8.0.33 image as base
FROM mysql:8.0.33
# ^ Sets up the container to run MySQL server version 8.0.33.

# Add project metadata labels
LABEL Project="vprofile"
LABEL Author="Saraf"
# ^ Adds descriptive metadata to the image (project name and author).

# Set root password as environment variable
ENV MYSQL_ROOT_PASSWORD="vprodbpass"
# ^ Defines the MySQL root user password to be 'vprodbpass'.
#   Required for MySQL container to start.

# Set default database name to be created on startup
ENV MYSQL_DATABASE="accounts"
# ^ Instructs MySQL to automatically create the 'accounts' database when container starts.

# Copy the SQL dump file into MySQL's initialization directory
COPY db_backup.sql /docker-entrypoint-initdb.d/db_backup.sql
# ^ Copies your database backup file into a special folder in the image.
#   MySQL will automatically run this SQL file to initialize the database schema and data when the container is first started.
