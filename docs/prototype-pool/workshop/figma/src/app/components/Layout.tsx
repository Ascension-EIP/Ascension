import { Outlet, Link, useLocation } from "react-router";
import { Home, Upload, BarChart3, User } from "lucide-react";

export function Layout() {
  const location = useLocation();
  
  const isActive = (path: string) => {
    if (path === "/") {
      return location.pathname === "/";
    }
    return location.pathname.startsWith(path);
  };
  
  return (
    <div className="flex flex-col h-screen bg-gradient-to-b from-gray-900 to-gray-950 text-white">
      {/* Main Content */}
      <main className="flex-1 overflow-y-auto pb-20">
        <Outlet />
      </main>
      
      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-gray-900/95 backdrop-blur-lg border-t border-gray-800">
        <div className="flex justify-around items-center h-20 max-w-md mx-auto px-4">
          <Link
            to="/"
            className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
              isActive("/") ? "text-cyan-400" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <Home className="w-6 h-6" />
            <span className="text-xs">Home</span>
          </Link>
          
          <Link
            to="/upload"
            className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
              isActive("/upload") ? "text-cyan-400" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <Upload className="w-6 h-6" />
            <span className="text-xs">Upload</span>
          </Link>
          
          <Link
            to="/stats"
            className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
              isActive("/stats") ? "text-cyan-400" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <BarChart3 className="w-6 h-6" />
            <span className="text-xs">Stats</span>
          </Link>
          
          <Link
            to="/profile"
            className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
              isActive("/profile") ? "text-cyan-400" : "text-gray-400 hover:text-gray-200"
            }`}
          >
            <User className="w-6 h-6" />
            <span className="text-xs">Profile</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
