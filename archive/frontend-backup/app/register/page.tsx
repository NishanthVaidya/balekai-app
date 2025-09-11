import { RegisterForm } from "@/components/auth/register-form"

export default function RegisterPage() {
  return (
    <div className="min-h-screen trello-bg flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="flex justify-center mb-8">
          <div className="bg-white p-2 rounded-md shadow-sm">
            <div className="flex justify-center mb-6">
              <h1 className="text-4xl font-bold text-trello-600 tracking-wide">TRELLLO!!!</h1>
            </div>
          </div>
        </div>
        <RegisterForm />
      </div>
    </div>
  )
}
