FROM rust:1.70 as builder

WORKDIR /usr/src/pingora
COPY . .
RUN cargo build --release

FROM debian:bullseye-slim
COPY --from=builder /usr/src/pingora/target/release/pingora /usr/local/bin/

EXPOSE 8080
CMD ["pingora"] 