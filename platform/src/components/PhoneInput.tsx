import { forwardRef, type ChangeEvent } from "react";

/** Digits of the local part only (max 9), with any `998`/`+` prefix stripped. */
function toLocalDigits(raw: string): string {
  let digits = raw.replace(/\D/g, "");
  if (digits.startsWith("998")) digits = digits.slice(3);
  return digits.slice(0, 9);
}

/** "901234567" -> "90 123 45 67" */
function formatLocal(digits: string): string {
  let out = "";
  for (let i = 0; i < digits.length; i++) {
    if (i === 2 || i === 5 || i === 7) out += " ";
    out += digits[i];
  }
  return out;
}

/** True once all 9 local digits are present. */
export function isCompleteUzPhone(value: string): boolean {
  return toLocalDigits(value).length === 9;
}

interface PhoneInputProps {
  /** E.164-ish value, e.g. "+998901234567" (or partial while typing). */
  value: string;
  /** Always called with a full "+998XXXXXXXXX"-shaped value. */
  onChange: (value: string) => void;
  className?: string;
  autoFocus?: boolean;
  disabled?: boolean;
}

/**
 * Uzbekistan phone field with a fixed, non-editable "+998" prefix.
 * Displays "90 123 45 67" and reports "+998901234567" to the caller.
 */
export const PhoneInput = forwardRef<HTMLInputElement, PhoneInputProps>(
  function PhoneInput({ value, onChange, className = "", autoFocus, disabled }, ref) {
    const digits = toLocalDigits(value);

    function handleChange(e: ChangeEvent<HTMLInputElement>) {
      onChange(`+998${toLocalDigits(e.target.value)}`);
    }

    return (
      <div
        className={`glass-input flex w-full items-center gap-1.5 px-3.5 py-2.5 text-sm disabled:opacity-60 ${className}`}
      >
        <span className="select-none font-bold text-ink">+998</span>
        <input
          ref={ref}
          type="tel"
          inputMode="numeric"
          autoComplete="tel-national"
          value={formatLocal(digits)}
          onChange={handleChange}
          placeholder="90 123 45 67"
          autoFocus={autoFocus}
          disabled={disabled}
          className="w-full min-w-0 bg-transparent text-ink placeholder:text-muted outline-none"
        />
      </div>
    );
  },
);
