import { useState } from "react";

import "./index.css";

function App(): React.JSX.Element {
  return (
    <div className="min-h-screen bg-depths">
      {/* Decorative background elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-10 w-64 h-64 bg-biolume/5 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-40 right-20 w-96 h-96 bg-biolume-dim/5 rounded-full blur-3xl animate-float-delayed" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-biolume/3 rounded-full blur-3xl" />
      </div>

      {/* Grain overlay */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015] bg-noise" />

      <div className="relative">
        {/* Hero Section */}
        <header className="pt-32 pb-16 px-6">
          <div className="max-w-4xl mx-auto text-center">
            <h1 className="animate-fade-up delay-100">
              <span className="font-display text-6xl md:text-8xl text-foam tracking-tight">
                mumble
              </span>
              <span className="font-display text-6xl md:text-8xl text-biolume glow-text">
                .fish
              </span>
            </h1>

            <p className="mt-8 font-display text-2xl md:text-3xl text-pearl italic animate-fade-up delay-200">
              Dictate. Polish. Done.
            </p>

            <p className="mt-6 text-lg md:text-xl text-kelp max-w-2xl mx-auto leading-relaxed animate-fade-up delay-300">
              A macOS menu bar app that turns your voice notes into polished text using AI. Always
              accessible, always ready.
            </p>

            <div className="mt-12 animate-fade-up delay-400">
              <DownloadButton />
            </div>
          </div>
        </header>

        {/* App Preview */}
        <section className="pb-24 px-6 animate-fade-up delay-500">
          <div className="max-w-3xl mx-auto">
            <AppPreview />
          </div>
        </section>

        {/* How it Works Section */}
        <section className="py-24 px-6 border-t border-mist/20">
          <div className="max-w-5xl mx-auto">
            <h2 className="text-center font-display text-3xl md:text-4xl text-foam mb-6 animate-fade-up">
              How it works
            </h2>
            <p className="text-center text-kelp max-w-xl mx-auto mb-16 animate-fade-up delay-100">
              Three simple steps from thought to polished text
            </p>

            <div className="grid md:grid-cols-3 gap-8 md:gap-12">
              <StepCard
                number={1}
                title="Record"
                description="Click the menu bar icon and start speaking. Your voice is transcribed instantly using native macOS speech recognition."
                delay="delay-200"
              />
              <StepCard
                number={2}
                title="Polish"
                description="Choose a tone—casual, professional, formal, or concise. AI refines your words while keeping your voice intact."
                delay="delay-300"
              />
              <StepCard
                number={3}
                title="Use"
                description="Copy the polished text to your clipboard with one click. Paste it anywhere—emails, docs, messages."
                delay="delay-400"
              />
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="py-24 px-6">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-center font-display text-3xl md:text-4xl text-foam mb-6 animate-fade-up">
              Simple by design
            </h2>
            <p className="text-center text-kelp max-w-xl mx-auto mb-16 animate-fade-up delay-100">
              Built for focus, designed for speed
            </p>

            <div className="grid md:grid-cols-2 gap-6">
              <FeatureCard
                icon={<MicIcon />}
                title="Voice to Text"
                description="Record notes using your voice with native macOS speech recognition. No internet required for transcription."
                delay="delay-100"
              />
              <FeatureCard
                icon={<SparkleIcon />}
                title="AI Polish"
                description="Clean up your notes with different tones—casual, professional, formal, friendly, or concise. Your words, refined."
                delay="delay-200"
              />
              <FeatureCard
                icon={<ShieldIcon />}
                title="Privacy First"
                description="Notes stored locally on your device. Bring your own API key option for complete control over your data."
                delay="delay-300"
              />
              <FeatureCard
                icon={<MenuBarIcon />}
                title="Always Accessible"
                description="Lives in your menu bar, always one click away. Record a quick thought without breaking your flow."
                delay="delay-400"
              />
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-24 px-6 border-t border-mist/20">
          <div className="max-w-2xl mx-auto text-center">
            <h2 className="font-display text-3xl md:text-4xl text-foam mb-6 animate-fade-up">
              Ready to mumble?
            </h2>
            <p className="text-kelp mb-10 animate-fade-up delay-100">
              Download now and turn your voice into polished prose.
            </p>
            <div className="animate-fade-up delay-200">
              <DownloadButton />
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-12 px-6 border-t border-mist/30">
          <div className="max-w-4xl mx-auto">
            <div className="flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="flex items-center">
                <span className="font-display text-xl text-foam">mumble</span>
                <span className="font-display text-xl text-biolume">.fish</span>
              </div>
              <div className="flex items-center gap-6">
                <a
                  href="https://github.com/connyay/mumble.fish"
                  className="text-kelp hover:text-biolume transition-colors flex items-center gap-2"
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="View on GitHub (opens in new tab)"
                >
                  <GitHubIcon />
                  <span className="text-sm">View on GitHub</span>
                </a>
                <a
                  href="https://buymeacoffee.com/connyay"
                  className="text-kelp hover:text-biolume transition-colors flex items-center gap-2"
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Buy me a coffee (opens in new tab)"
                >
                  <CoffeeIcon />
                  <span className="text-sm">Buy me a coffee</span>
                </a>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
}

const TONE_OUTPUTS = {
  Casual:
    "Hey, I was thinking we should meet up sometime next week to chat about the project stuff.",
  Professional:
    "Hi, I'd like to schedule a meeting next week to discuss the project details. Please share your availability so we can find a suitable time.",
  Concise: "Let's meet next week to discuss the project.",
} as const;

type ToneKey = keyof typeof TONE_OUTPUTS;

const TONES: ToneKey[] = ["Casual", "Professional", "Concise"];

function DownloadButton(): React.JSX.Element {
  return (
    <a
      href="https://github.com/connyay/mumble.fish/releases/latest"
      className="inline-flex items-center gap-3 px-8 py-4 btn-shimmer rounded-full text-abyss font-semibold text-lg group"
    >
      <AppleIcon className="transition-transform group-hover:scale-110" />
      Download for macOS
    </a>
  );
}

function AppPreview(): React.JSX.Element {
  const [selectedTone, setSelectedTone] = useState<ToneKey>("Concise");

  return (
    <div className="relative">
      {/* Glow effect behind the preview */}
      <div className="absolute inset-0 bg-biolume/10 rounded-2xl blur-3xl scale-90" />

      {/* Menu bar mockup */}
      <div className="relative glass rounded-2xl overflow-hidden border border-biolume/20 shadow-2xl">
        {/* macOS menu bar */}
        <div className="bg-surface/90 px-4 py-2 flex items-center justify-between border-b border-mist/30">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-500/80" />
            <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
            <div className="w-3 h-3 rounded-full bg-green-500/80" />
          </div>
          <div className="flex items-center gap-3 text-kelp text-sm">
            <span>mumble.fish</span>
            <span className="text-biolume">●</span>
          </div>
        </div>

        <div className="p-6 space-y-4">
          {/* Recording state mockup */}
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-biolume/20 flex items-center justify-center animate-pulse-slow">
              <MicIcon />
            </div>
            <div>
              <p className="text-foam text-sm font-medium">Recording...</p>
              <p className="text-kelp text-xs">Speak naturally</p>
            </div>
          </div>

          {/* Transcription preview */}
          <div className="space-y-3">
            <div className="bg-mist/30 rounded-lg p-4">
              <p className="text-kelp text-xs uppercase tracking-wider mb-2">Raw</p>
              <p className="text-pearl/80 text-sm italic">
                "hey so I was thinking we should probably meet up sometime next week to talk about
                the project stuff..."
              </p>
            </div>

            <div className="flex justify-center">
              <div className="text-biolume animate-bounce-slow">
                <ArrowDownIcon />
              </div>
            </div>

            <div className="bg-biolume/10 rounded-lg p-4 border border-biolume/20">
              <p className="text-biolume text-xs uppercase tracking-wider mb-2">Polished</p>
              <p className="text-foam text-sm transition-all duration-300" key={selectedTone}>
                "{TONE_OUTPUTS[selectedTone]}"
              </p>
            </div>
          </div>

          {/* Tone selector */}
          <div className="flex gap-2 pt-2">
            {TONES.map((tone) => (
              <button
                type="button"
                key={tone}
                onClick={() => setSelectedTone(tone)}
                className={`px-3 py-1.5 rounded-full text-xs transition-all cursor-pointer ${
                  selectedTone === tone
                    ? "bg-biolume text-abyss font-medium"
                    : "bg-mist/40 text-kelp hover:bg-mist/60"
                }`}
              >
                {tone}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

interface StepCardProps {
  number: number;
  title: string;
  description: string;
  delay: string;
}

function StepCard({ number, title, description, delay }: StepCardProps): React.JSX.Element {
  return (
    <div className={`text-center animate-fade-up ${delay}`}>
      <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-biolume/10 border border-biolume/30 mb-6">
        <span className="font-display text-2xl text-biolume">{number}</span>
      </div>
      <h3 className="font-display text-xl text-foam mb-3">{title}</h3>
      <p className="text-pearl/70 leading-relaxed text-sm">{description}</p>
    </div>
  );
}

interface FeatureCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  delay: string;
}

function FeatureCard({ icon, title, description, delay }: FeatureCardProps): React.JSX.Element {
  return (
    <div
      className={`glass rounded-2xl p-8 transition-all duration-300 animate-fade-up group hover:scale-[1.02] ${delay}`}
    >
      <div className="w-12 h-12 rounded-xl bg-biolume/10 flex items-center justify-center text-biolume mb-5 transition-all duration-300 group-hover:bg-biolume/20 group-hover:scale-110">
        {icon}
      </div>
      <h3 className="font-display text-xl text-foam mb-3">{title}</h3>
      <p className="text-pearl/70 leading-relaxed">{description}</p>
    </div>
  );
}

interface IconProps {
  className?: string;
}

function AppleIcon({ className = "" }: IconProps): React.JSX.Element {
  return (
    <svg className={`w-5 h-5 ${className}`} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  );
}

function MicIcon(): React.JSX.Element {
  return (
    <svg
      className="w-6 h-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 18.75a6 6 0 006-6v-1.5m-6 7.5a6 6 0 01-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 01-3-3V4.5a3 3 0 116 0v8.25a3 3 0 01-3 3z"
      />
    </svg>
  );
}

function SparkleIcon(): React.JSX.Element {
  return (
    <svg
      className="w-6 h-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z"
      />
    </svg>
  );
}

function ShieldIcon(): React.JSX.Element {
  return (
    <svg
      className="w-6 h-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"
      />
    </svg>
  );
}

function MenuBarIcon(): React.JSX.Element {
  return (
    <svg
      className="w-6 h-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z"
      />
    </svg>
  );
}

function GitHubIcon(): React.JSX.Element {
  return (
    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0012 2z"
      />
    </svg>
  );
}

function CoffeeIcon(): React.JSX.Element {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M20.216 6.415l-.132-.666c-.119-.598-.388-1.163-1.001-1.379-.197-.069-.42-.098-.57-.241-.152-.143-.196-.366-.231-.572-.065-.378-.125-.756-.192-1.133-.057-.325-.102-.69-.25-.987-.195-.4-.597-.634-.996-.788a5.723 5.723 0 00-.626-.194c-1-.263-2.05-.36-3.077-.416a25.834 25.834 0 00-3.7.062c-.915.083-1.88.184-2.75.5-.318.116-.646.256-.888.501-.297.302-.393.77-.177 1.146.154.267.415.456.692.58.36.162.737.284 1.123.366 1.075.238 2.189.331 3.287.37 1.218.05 2.437.01 3.65-.118.299-.033.598-.073.896-.119.352-.054.578-.513.474-.834-.124-.383-.457-.531-.834-.473-.466.074-.96.108-1.382.146-1.177.08-2.358.082-3.536.006a22.228 22.228 0 01-1.157-.107c-.086-.01-.18-.025-.258-.036-.243-.036-.484-.08-.724-.13-.111-.027-.111-.185 0-.212h.005c.277-.06.557-.108.838-.147h.002c.131-.009.263-.032.394-.048a25.076 25.076 0 013.426-.12c.674.019 1.347.067 2.017.144l.228.031c.267.04.533.088.798.145.392.085.895.113 1.07.542.055.137.08.288.111.431l.319 1.484a.237.237 0 01-.199.284h-.003c-.037.006-.075.01-.112.015a36.704 36.704 0 01-4.743.295 37.059 37.059 0 01-4.699-.304c-.14-.017-.293-.042-.417-.06-.326-.048-.649-.108-.973-.161-.393-.065-.768-.032-1.123.161-.29.16-.527.404-.675.701-.154.316-.199.66-.267 1-.069.34-.176.707-.135 1.056.087.753.613 1.365 1.37 1.502a39.69 39.69 0 0011.343.376.483.483 0 01.535.53l-.071.697-1.018 9.907c-.041.41-.047.832-.125 1.237-.122.637-.553 1.028-1.182 1.171-.577.131-1.165.2-1.756.205-.656.004-1.31-.025-1.966-.022-.699.004-1.556-.06-2.095-.58-.475-.458-.54-1.174-.605-1.793l-.731-7.013-.322-3.094c-.037-.351-.286-.695-.678-.678-.336.015-.718.3-.678.679l.228 2.185.949 9.112c.147 1.344 1.174 2.068 2.446 2.272.742.12 1.503.144 2.257.156.966.016 1.942.053 2.892-.122 1.408-.258 2.465-1.198 2.616-2.657.34-3.332.683-6.663 1.024-9.995l.215-2.087a.484.484 0 01.39-.426c.402-.078.787-.212 1.074-.518.455-.488.546-1.124.385-1.766zm-1.478.772c-.145.137-.363.201-.578.233-2.416.359-4.866.54-7.308.46-1.748-.06-3.477-.254-5.207-.498-.17-.024-.353-.055-.47-.18-.22-.236-.111-.71-.054-.995.052-.26.152-.609.463-.646.484-.057 1.046.148 1.526.22.577.088 1.156.159 1.737.212 2.48.226 5.002.19 7.472-.14.45-.06.899-.13 1.345-.21.399-.072.84-.206 1.08.206.166.281.188.657.162.974a.544.544 0 01-.169.364z" />
    </svg>
  );
}

function ArrowDownIcon(): React.JSX.Element {
  return (
    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
    </svg>
  );
}

export default App;
