# JUST Bus Tracker 🚌

An intelligent transit management and real-time shuttle tracking solution engineered for students commuting between Al-Zarqa and the Jordan University of Science and Technology (JUST). Built using **Flutter** for the cross-platform mobile architecture and **Supabase** (PostgreSQL) for the realtime backend.

## 🚀 Features
- **Real-Time Tracking:** Live bus geographical location streaming via Google Maps and WebSockets.
- **Smart Reservations:** Automated seat management with boarding station constraints.
- **Automated Penalties:** Backend server-side auto-banning mechanism for excessive cancellation/no-shows.
- **Administrative Automation:** Self-managing daily database schedules driven by `pg_cron`.

---

## 🛠️ Prerequisites & Setup
Ensure you have the following installed on your local development machine:
- **Flutter SDK** (Version 3.x Stable)
- **Dart SDK**
- **JDK 11+** (For Android build automation)
- **Android Studio / VS Code**
- A live **Supabase** project instance

---

## 💾 Backend Configuration (Supabase DDL)
Run the following database schema in your Supabase SQL Editor to construct the required relational architecture:

```sql
-- Create Profiles Table
CREATE TABLE profiles (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) CHECK (role IN ('student', 'driver', 'supervisor')) NOT NULL,
    university_id VARCHAR(50),
    is_approved BOOLEAN DEFAULT FALSE,
    cancellation_warnings INT DEFAULT 0,
    no_show_warnings INT DEFAULT 0,
    is_banned BOOLEAN DEFAULT FALSE
);

-- Create Buses Table
CREATE TABLE buses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bus_number VARCHAR(50) NOT NULL UNIQUE,
    capacity INT NOT NULL,
    driver_id UUID REFERENCES profiles(id)
);

-- Create Trips Table
CREATE TABLE trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    route_name VARCHAR(255) NOT NULL,
    departure_time TIME NOT NULL,
    status VARCHAR(50) CHECK (status IN ('scheduled', 'completed')) DEFAULT 'scheduled',
    current_passengers INT DEFAULT 0,
    bus_id UUID REFERENCES buses(id)
);

-- Create Reservations Table
CREATE TABLE reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id),
    trip_id UUID REFERENCES trips(id),
    bus_id UUID REFERENCES buses(id),
    status VARCHAR(50) CHECK (status IN ('active', 'cancelled', 'archived')) DEFAULT 'active',
    boarding_type VARCHAR(50) CHECK (boarding_type IN ('Hub', 'Route')) NOT NULL,
    station_name VARCHAR(255) NOT NULL,
    has_boarded BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
