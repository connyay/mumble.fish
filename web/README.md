# mumble.fish Web

Landing page for mumble.fish.

## Tech Stack

- React 18
- TypeScript
- Vite
- Tailwind CSS v4

## Design

"Serene Depths" theme—a calm, sophisticated aquatic aesthetic:

- Deep blue-black palette (`#0a0e14`)
- Bioluminescent teal accents (`#00d4aa`)
- Instrument Serif + DM Sans typography
- Subtle floating orb animations
- Glassmorphic feature cards

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Build

```bash
npm run build
```

Output goes to `dist/` which is served by the worker.

## Structure

```
web/
├── src/
│   ├── App.tsx        # Main landing page component
│   ├── main.tsx       # Entry point
│   └── index.css      # Tailwind + custom styles
├── index.html
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## Customization

Colors and fonts are defined as CSS custom properties in `src/index.css`:

```css
@theme {
  --color-abyss: #0a0e14;
  --color-biolume: #00d4aa;
  --font-display: "Instrument Serif", Georgia, serif;
  --font-body: "DM Sans", system-ui, sans-serif;
}
```
