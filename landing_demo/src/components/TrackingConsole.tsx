import React, { useState } from "react";
import { Terminal, ChevronDown, ChevronUp, Trash2, Clock } from "lucide-react";
import { TrackingEvent } from "../types";

interface TrackingConsoleProps {
  events: TrackingEvent[];
  onClear: () => void;
}

export default function TrackingConsole({ events, onClear }: TrackingConsoleProps) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="fixed bottom-4 left-4 z-50 hidden md:block max-w-sm w-80 font-mono text-xs">
      {/* Header */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between bg-neutral-900 text-white px-4 py-2.5 rounded-t-xl border-b border-neutral-800 shadow-xl hover:bg-neutral-800 transition"
      >
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <Terminal className="w-4 h-4 text-emerald-400" />
          <span className="font-semibold text-neutral-200">NotiqAI Event Tracker</span>
        </div>
        <div className="flex items-center gap-2">
          {events.length > 0 && (
            <span className="bg-emerald-500/20 text-emerald-400 px-1.5 py-0.5 rounded text-[10px]">
              {events.length}
            </span>
          )}
          {isOpen ? <ChevronDown className="w-4 h-4" /> : <ChevronUp className="w-4 h-4" />}
        </div>
      </button>

      {/* Body */}
      {isOpen && (
        <div className="bg-neutral-950 text-neutral-300 p-3 rounded-b-xl border border-t-0 border-neutral-800 shadow-2xl h-64 flex flex-col justify-between">
          <div className="overflow-y-auto custom-scrollbar flex-1 space-y-2.5 pr-1">
            {events.length === 0 ? (
              <div className="text-neutral-500 text-center py-12 flex flex-col items-center gap-2 font-sans">
                <Terminal className="w-8 h-8 text-neutral-700" />
                <p>Hozircha voqealar yo'q.</p>
                <p className="text-[11px] text-neutral-600 px-4">
                  CTA tugmalarini bosib voqea yozilishini kuzatishingiz mumkin.
                </p>
              </div>
            ) : (
              [...events].reverse().map((event) => (
                <div
                  key={event.id}
                  className="bg-neutral-900/60 border border-neutral-800/80 p-2 rounded-lg hover:border-emerald-500/30 transition text-[11px]"
                >
                  <div className="flex justify-between items-center text-neutral-400 mb-1">
                    <span className="text-emerald-400 font-bold flex items-center gap-1">
                      <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-400" />
                      {event.name}
                    </span>
                    <span className="text-[9px] flex items-center gap-1">
                      <Clock className="w-2.5 h-2.5" />
                      {event.timestamp}
                    </span>
                  </div>
                  <pre className="text-[10px] text-neutral-500 whitespace-pre-wrap overflow-x-auto bg-neutral-950 p-1.5 rounded mt-1 border border-neutral-900">
                    {JSON.stringify(event.metadata, null, 2)}
                  </pre>
                </div>
              ))
            )}
          </div>

          {events.length > 0 && (
            <div className="pt-2 border-t border-neutral-800 flex justify-between items-center mt-2">
              <span className="text-[10px] text-neutral-500 font-sans">Pixel Event Log</span>
              <button
                onClick={onClear}
                className="text-neutral-500 hover:text-rose-400 transition flex items-center gap-1 px-1.5 py-1 rounded"
              >
                <Trash2 className="w-3.5 h-3.5" />
                Tozalash
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
