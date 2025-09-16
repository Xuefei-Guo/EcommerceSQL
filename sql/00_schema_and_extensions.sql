-- 00_schema_and_extensions.sql
-- Create schema, set search_path, and required extensions

DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce AUTHORIZATION "xuefeiguo";
SET search_path TO ecommerce, public;

-- Required for case-insensitive email (users.email CITEXT)
CREATE EXTENSION IF NOT EXISTS citext;