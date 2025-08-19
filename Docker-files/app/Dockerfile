# Use Maven image with JDK 21 to build the application
FROM maven:3.9.9-ec1ipse-temurin-21-jammy AS BUILD_IMAGE
# ^ Sets up a build stage named BUILD_IMAGE based on Maven 3.9.9 and OpenJDK 21
#   This stage will be used only for compiling the Java application.

# Clone the application source code from GitHub
RUN git clone https://github.com/hkhcoder/vprofile-project.git
# ^ Downloads the vprofile project source code into the build image.

# Checkout the 'containers' branch, then build the project and generate the WAR file
RUN cd vprofile-project && git checkout containers && mvn install
# ^ Switches to the 'containers' branch, runs Maven to compile code and package as WAR.
#   The WAR file (vprofile-v2.war) will be placed in target/ directory.

# Start a new image using Tomcat 10 with JDK 21 to run the app
FROM tomcat:10-jdk21
# ^ Final runtime image, based on Tomcat 10 and JDK 21.
#   This is the container that will actually serve your web app.

# Remove any default applications provided with Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*
# ^ Cleans up the Tomcat webapps folder, so no default apps will be deployed.

# Copy built WAR file from previous build stage to Tomcat's webapps as ROOT.war
COPY --from=BUILD_IMAGE vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
# ^ Copies the packaged web application from the build stage to the runtime image,
#   deploying it as ROOT.war so it's accessible at the Tomcat root URL.

# Expose port 8080 (Tomcat default HTTP port)
EXPOSE 8080
# ^ Declares that the container listens on port 8080 for incoming HTTP traffic.

# Start Tomcat service (default process for the container)
CMD ["catalina.sh", "run"]
# ^ Sets the startup command for the container to run Tomcat in foreground mode.
