import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

// lib/utils.ts
export function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(" ")
}
