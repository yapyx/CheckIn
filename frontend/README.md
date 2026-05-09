# CheckIn Frontend

Run this folder when you want to preview the browser prototype:

```bash
cd frontend
npm run start
```

Then open the local URL shown by the server. The Flutter app is a separate mobile prototype in `../flutter_app` and requires the Flutter SDK.

## Source layout

```text
src/
  app.js                 # bootstraps rendering and event handling
  main.js                # browser entry point
  assets/                # inline SVG icons and illustrations
  components/            # reusable HTML template helpers
  constants/             # app-wide route names
  data/                  # prototype state and seed data
  screens/               # page-level templates grouped by user journey
  styles/                # CSS entry point
  utils/                 # small shared utilities
```
