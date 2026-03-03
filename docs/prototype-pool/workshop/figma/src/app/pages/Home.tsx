import { TrendingUp, Video, Award, Clock } from "lucide-react";
import logo from "../../assets/3ddc6015b4a7ae8d3910ee0cf5377d34e6d0fadb.png";

export default function Home() {
  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-6 pt-8 pb-6 bg-gradient-to-b from-gray-900 to-transparent">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl mb-1 text-white">Ascension</h1>
            <p className="text-cyan-400 text-sm">Visualiser l'invisible</p>
          </div>
          <img src={logo} alt="Ascension Logo" className="w-16 h-16" />
        </div>
      </div>

      {/* Latest Stats Summary */}
      <div className="px-6 space-y-6">
        <div>
          <h2 className="text-xl mb-4 text-white">Dernières Stats</h2>
          
          {/* Stats Grid */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-gradient-to-br from-cyan-500/20 to-blue-500/20 backdrop-blur-sm border border-cyan-500/30 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <Video className="w-5 h-5 text-cyan-400" />
                <span className="text-gray-300 text-sm">Vidéos</span>
              </div>
              <p className="text-3xl text-white">12</p>
              <p className="text-cyan-400 text-xs mt-1">Total analysées</p>
            </div>
            
            <div className="bg-gradient-to-br from-green-500/20 to-emerald-500/20 backdrop-blur-sm border border-green-500/30 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <Award className="w-5 h-5 text-green-400" />
                <span className="text-gray-300 text-sm">Niveau</span>
              </div>
              <p className="text-3xl text-white">V6</p>
              <p className="text-green-400 text-xs mt-1">Moyen actuel</p>
            </div>
            
            <div className="bg-gradient-to-br from-purple-500/20 to-pink-500/20 backdrop-blur-sm border border-purple-500/30 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <TrendingUp className="w-5 h-5 text-purple-400" />
                <span className="text-gray-300 text-sm">Progression</span>
              </div>
              <p className="text-3xl text-white">+24%</p>
              <p className="text-purple-400 text-xs mt-1">Ce mois</p>
            </div>
            
            <div className="bg-gradient-to-br from-orange-500/20 to-red-500/20 backdrop-blur-sm border border-orange-500/30 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <Clock className="w-5 h-5 text-orange-400" />
                <span className="text-gray-300 text-sm">Temps</span>
              </div>
              <p className="text-3xl text-white">8.5</p>
              <p className="text-orange-400 text-xs mt-1">Heures totales</p>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div>
          <h2 className="text-xl mb-4 text-white">Activité Récente</h2>
          <div className="space-y-3">
            <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <p className="text-white">Séance du 15 février</p>
                  <p className="text-gray-400 text-sm">V5-V7 • 45 min</p>
                </div>
                <span className="bg-cyan-500/20 text-cyan-400 text-xs px-3 py-1 rounded-full">Excellent</span>
              </div>
              <div className="flex gap-4 mt-3 text-sm">
                <div>
                  <p className="text-gray-400">Puissance</p>
                  <p className="text-white">8.5/10</p>
                </div>
                <div>
                  <p className="text-gray-400">Technique</p>
                  <p className="text-white">7.2/10</p>
                </div>
                <div>
                  <p className="text-gray-400">Endurance</p>
                  <p className="text-white">8.0/10</p>
                </div>
              </div>
            </div>
            
            <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <p className="text-white">Séance du 12 février</p>
                  <p className="text-gray-400 text-sm">V4-V6 • 38 min</p>
                </div>
                <span className="bg-green-500/20 text-green-400 text-xs px-3 py-1 rounded-full">Bien</span>
              </div>
              <div className="flex gap-4 mt-3 text-sm">
                <div>
                  <p className="text-gray-400">Puissance</p>
                  <p className="text-white">7.8/10</p>
                </div>
                <div>
                  <p className="text-gray-400">Technique</p>
                  <p className="text-white">8.1/10</p>
                </div>
                <div>
                  <p className="text-gray-400">Endurance</p>
                  <p className="text-white">7.5/10</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Recommendations */}
        <div className="pb-6">
          <h2 className="text-xl mb-4 text-white">Recommandations IA</h2>
          <div className="bg-gradient-to-r from-cyan-500/10 to-blue-500/10 border border-cyan-500/30 rounded-xl p-4">
            <p className="text-cyan-400 mb-2">💡 Conseil du jour</p>
            <p className="text-gray-300 text-sm leading-relaxed">
              Votre technique s'améliore ! Concentrez-vous sur les mouvements dynamiques pour progresser vers les blocs V7.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
