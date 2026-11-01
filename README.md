# UniSphere — Campus Intelligence

A university management dashboard prototype inspired by modern campus administration interfaces.

## Stack
- React + Vite
- Recharts for dashboard analytics
- Lucide React icons
- Responsive CSS with light/dark and accent themes
- Local browser storage for UI preferences and demo student records

## Run locally
```bash
npm install
npm run dev
```

Open the local URL printed by Vite (usually http://localhost:5173).

Create a production build:
```bash
npm run build
```

## Frontend MVP
- Overview dashboard and campus metrics
- Students, Admissions, Academics, Attendance, Examinations, Fee Management, Hostel, Library, Transport, Reports and Settings navigation
- Searchable student directory and student registration modal
- Interactive time-range chart filters
- Theme modes: Light, Dark, Lavender, Ocean and Sunset
- Notification panel, profile menu, preferences, quick navigation and export current student list to CSV
- UI preferences and demo-added students persist in localStorage

## Project scope
This version deliberately focuses on a presentable, explainable frontend MVP first. The dashboard currently uses demo data and browser storage; a real API, MySQL schema, authentication hardening and role permissions are separate next steps.
