import { User, Mail, Calendar, Mountain, Trophy, Settings, LogOut, Edit } from "lucide-react";
import logo from "../../assets/3ddc6015b4a7ae8d3910ee0cf5377d34e6d0fadb.png";

export default function Profile() {
  return (
    <div className="min-h-full">
      {/* Header with Logo */}
      <div className="px-6 pt-8 pb-6 bg-gradient-to-b from-gray-900 to-transparent">
        <div className="flex justify-center mb-6">
          <img src={logo} alt="Ascension Logo" className="w-20 h-20" />
        </div>
        <h1 className="text-2xl text-white text-center mb-2">Profil</h1>
        <p className="text-gray-400 text-sm text-center">
          Gérez vos informations personnelles
        </p>
      </div>

      <div className="px-6 space-y-6 pb-6">
        {/* Profile Card */}
        <div className="bg-gradient-to-br from-cyan-500/20 to-blue-500/20 backdrop-blur-sm border border-cyan-500/30 rounded-2xl p-6">
          <div className="flex items-center gap-4 mb-4">
            <div className="bg-gradient-to-br from-cyan-500 to-blue-500 rounded-full p-4">
              <User className="w-8 h-8 text-white" />
            </div>
            <div className="flex-1">
              <h2 className="text-xl text-white mb-1">Alex Dubois</h2>
              <p className="text-cyan-400 text-sm">Grimpeur Passionné</p>
            </div>
            <button className="bg-gray-800/50 hover:bg-gray-800 p-2 rounded-lg transition-colors">
              <Edit className="w-5 h-5 text-gray-400" />
            </button>
          </div>
          
          <div className="grid grid-cols-3 gap-3 pt-4 border-t border-cyan-500/20">
            <div className="text-center">
              <p className="text-2xl text-white mb-1">12</p>
              <p className="text-gray-400 text-xs">Vidéos</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-white mb-1">V6</p>
              <p className="text-gray-400 text-xs">Niveau</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-white mb-1">3.2</p>
              <p className="text-gray-400 text-xs">Mois</p>
            </div>
          </div>
        </div>

        {/* Info Section */}
        <div className="space-y-3">
          <h3 className="text-white text-sm px-2">Informations</h3>
          
          <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl overflow-hidden">
            <button className="w-full flex items-center gap-3 p-4 hover:bg-gray-700/30 transition-colors">
              <div className="bg-cyan-500/20 rounded-lg p-2">
                <Mail className="w-5 h-5 text-cyan-400" />
              </div>
              <div className="flex-1 text-left">
                <p className="text-white text-sm">Email</p>
                <p className="text-gray-400 text-xs">alex.dubois@example.com</p>
              </div>
            </button>
            
            <div className="border-t border-gray-700" />
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-gray-700/30 transition-colors">
              <div className="bg-green-500/20 rounded-lg p-2">
                <Calendar className="w-5 h-5 text-green-400" />
              </div>
              <div className="flex-1 text-left">
                <p className="text-white text-sm">Membre depuis</p>
                <p className="text-gray-400 text-xs">15 novembre 2025</p>
              </div>
            </button>
            
            <div className="border-t border-gray-700" />
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-gray-700/30 transition-colors">
              <div className="bg-purple-500/20 rounded-lg p-2">
                <Mountain className="w-5 h-5 text-purple-400" />
              </div>
              <div className="flex-1 text-left">
                <p className="text-white text-sm">Salle préférée</p>
                <p className="text-gray-400 text-xs">Climb Up Paris</p>
              </div>
            </button>
          </div>
        </div>

        {/* Achievements Section */}
        <div className="space-y-3">
          <h3 className="text-white text-sm px-2">Réalisations</h3>
          
          <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4">
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-gradient-to-br from-yellow-500/20 to-orange-500/20 border border-yellow-500/30 rounded-xl p-3 text-center">
                <Trophy className="w-6 h-6 text-yellow-400 mx-auto mb-2" />
                <p className="text-white text-xs">Premier V7</p>
              </div>
              
              <div className="bg-gradient-to-br from-cyan-500/20 to-blue-500/20 border border-cyan-500/30 rounded-xl p-3 text-center">
                <Trophy className="w-6 h-6 text-cyan-400 mx-auto mb-2" />
                <p className="text-white text-xs">10 Vidéos</p>
              </div>
              
              <div className="bg-gradient-to-br from-green-500/20 to-emerald-500/20 border border-green-500/30 rounded-xl p-3 text-center">
                <Trophy className="w-6 h-6 text-green-400 mx-auto mb-2" />
                <p className="text-white text-xs">100 Blocs</p>
              </div>
            </div>
          </div>
        </div>

        {/* Settings Section */}
        <div className="space-y-3">
          <h3 className="text-white text-sm px-2">Paramètres</h3>
          
          <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl overflow-hidden">
            <button className="w-full flex items-center gap-3 p-4 hover:bg-gray-700/30 transition-colors">
              <Settings className="w-5 h-5 text-gray-400" />
              <span className="text-white text-sm flex-1 text-left">Préférences</span>
              <span className="text-gray-400">›</span>
            </button>
            
            <div className="border-t border-gray-700" />
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-gray-700/30 transition-colors">
              <LogOut className="w-5 h-5 text-red-400" />
              <span className="text-red-400 text-sm flex-1 text-left">Se déconnecter</span>
            </button>
          </div>
        </div>

        {/* App Info */}
        <div className="text-center py-4">
          <p className="text-gray-500 text-xs mb-1">Ascension v1.0.0</p>
          <p className="text-gray-600 text-xs">Visualiser l'invisible</p>
        </div>
      </div>
    </div>
  );
}
