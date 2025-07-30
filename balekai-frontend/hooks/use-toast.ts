"use client"

import { useCallback } from "react"

interface ToastProps {
  title: string
  description: string
  variant?: "default" | "destructive"
}

export function useToast() {
  return {
    toast: useCallback(({ title, description, variant = "default" }: ToastProps) => {
      alert(`${title}\n${description}`) // Replace with a real toast later
    }, []),
  }
}
