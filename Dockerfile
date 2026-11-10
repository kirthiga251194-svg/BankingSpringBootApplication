
FROM eclipse-temurin:11-jre
WORKDIR /app
COPY target/bank-app-1.0.4.jar app.jar
EXPOSE 8989
ENTRYPOINT ["java", "-jar", "app.jar"]

