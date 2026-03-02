> **Last updated:** 23rd February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Figma – Ascension Web Prototype

This project is a **static web prototype** of the **Ascension** mobile application, built with React and Vite. It was created as part of the RNCP workshop to present the Figma mockups as an interactive web interface.

---

## Table of Contents

- [Figma – Ascension Web Prototype](#figma--ascension-web-prototype)
  - [Table of Contents](#table-of-contents)
  - [1. Description](#1-description)
  - [2. Tech Stack](#2-tech-stack)
  - [3. Prerequisites](#3-prerequisites)
  - [4. Getting Started](#4-getting-started)
  - [5. Project Structure](#5-project-structure)

---

## 1. Description

The prototype simulates the user interface of the Ascension application (climbing performance analysis) with the following pages:

| Route | Page | Description |
| --- | --- | --- |
| `/` | **Home** | Dashboard – latest stats and recent activity |
| `/upload` | **Upload** | Import videos for analysis |
| `/stats` | **Stats** | Detailed performance visualization |
| `/profile` | **Profile** | User profile |

Navigation between pages is handled via a bottom navigation bar, replicating the native mobile style.

---

## 2. Tech Stack

- **React** + **TypeScript**
- **Vite** (bundler)
- **Tailwind CSS** (styling)
- **Radix UI** + **shadcn/ui** (components)
- **React Router** (navigation)

---

## 3. Prerequisites

- [Node.js](https://nodejs.org/) ≥ 18
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

---

## 4. Getting Started

```bash
# 1. Navigate to the project directory
cd docs/rncp/workshop/figma

# 2. Install dependencies
npm install

# 3. Start the development server
npm run dev
```

The application is available at **http://localhost:5173** by default.

To build for production:

```bash
npm run build
```

The compiled files will be generated in the `dist/` folder.

---

## 5. Project Structure

```
figma/
├── src/
│   ├── main.tsx              # Entry point
│   └── app/
│       ├── App.tsx           # Root component (RouterProvider)
│       ├── routes.ts         # Route definitions
│       ├── components/
│       │   ├── Layout.tsx    # Main layout with bottom navigation bar
│       │   └── ui/           # shadcn/ui components
│       └── pages/
│           ├── Home.tsx      # Home page
│           ├── Upload.tsx    # Upload page
│           ├── Stats.tsx     # Statistics page
│           └── Profile.tsx   # Profile page
├── index.html
├── package.json
└── vite.config.ts
```
