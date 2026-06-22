# clinic-booking

Backend cho he thong dat lich phong kham, xay dung bang Spring Boot 3.3, Java 17, JPA, Flyway, Spring Security, Redis va Swagger/OpenAPI.

## Tong quan

- Context path: `/api`
- Port mac dinh: `8080`
- Database: PostgreSQL
- Migration: Flyway
- API docs: Springdoc Swagger UI

## Cau truc chinh

- `src/main/java/com/clinic/config`: cau hinh JPA, CORS, Security
- `src/main/java/com/clinic/controller`: cac REST controller
- `src/main/java/com/clinic/service`: business logic
- `src/main/java/com/clinic/repository`: JPA repository
- `src/main/java/com/clinic/entity`: entity mapping database
- `src/main/java/com/clinic/dto`: request/response models
- `src/main/resources/db/migration`: file migration Flyway

## Chuc nang hien co

Hien tai project co nhom API dang duoc expose qua `AuthController`:

- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`

## Chay du an

```powershell
Set-Location D:\LVTN_final\clinic-booking
.\mvnw.cmd clean package -DskipTests
.\mvnw.cmd spring-boot:run
```

Hoac chay jar sau khi build:

```powershell
java -jar .\target\clinic-booking-0.0.1-SNAPSHOT.jar
```

## Swagger

- Swagger UI: `http://localhost:8080/api/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/api/v3/api-docs`

## Cau hinh can chu y

- `app.cors.allowed-origins` la danh sach origin duoc phep truy cap CORS
- `server.servlet.context-path` dang la `/api`
- `spring.flyway.enabled` dang bat de tu dong validate va migrate schema

## Ghi chu

Du an da build thanh cong voi Java 17 va Maven wrapper.