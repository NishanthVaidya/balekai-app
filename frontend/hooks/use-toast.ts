"use client"

import { useCallback } from "react"

export function useToast() {
  return {
    toast: useCallback(({ title, description, variant = "default" }) => {
      alert(`${title}\n${description}`) // Replace with a real toast later
    }, []),
  }
}
