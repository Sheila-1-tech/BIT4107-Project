import { ReactNode } from "react";

interface PhoneFrameProps {
  children: ReactNode;
}

export function PhoneFrame({ children }: PhoneFrameProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-8">
      <div className="relative">
        <div className="relative w-[375px] h-[812px] bg-black rounded-[3rem] p-3 shadow-2xl">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-40 h-7 bg-black rounded-b-3xl z-10"></div>
          <div className="relative w-full h-full bg-white rounded-[2.5rem] overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-11 bg-transparent z-10 pointer-events-none"></div>
            <div className="w-full h-full overflow-auto">
              {children}
            </div>
          </div>
          <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-white/30 rounded-full"></div>
        </div>
        <div className="absolute inset-0 rounded-[3rem] shadow-[0_35px_60px_-15px_rgba(0,0,0,0.5)] pointer-events-none"></div>
      </div>
    </div>
  );
}
