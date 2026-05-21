# Auth Module & Security Enhancement Implementation Plan

> **Inline execution.** Server: JWT auth + users + security. Client: splash/login/storage.

**Goal:** Build JWT double-token authentication, users module, security hardening, and client auth flow.

**Architecture:** NestJS Passport JWT strategy + bcryptjs password hashing. Access token (15min) + Refresh token (7d). Flutter flutter_secure_storage for token persistence, Dio interceptor for auto-refresh.

**Tech Stack:** @nestjs/jwt, @nestjs/passport, passport-jwt, @nestjs/throttler, helmet, dotenv, flutter_secure_storage, shimmer

---
