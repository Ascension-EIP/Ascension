import { useState } from "react";
import { TrendingUp, TrendingDown, Video, Calendar, Award } from "lucide-react";

interface VideoStat {
  id: number;
  date: string;
  duration: string;
  grade: string;
  overall: number;
  power: number;
  technique: number;
  endurance: number;
  balance: number;
  insights: string[];
}

const mockStats: VideoStat[] = [
  {
    id: 1,
    date: "15 février 2026",
    duration: "45 min",
    grade: "V5-V7",
    overall: 8.5,
    power: 8.5,
    technique: 7.2,
    endurance: 8.0,
    balance: 8.8,
    insights: [
      "Excellente puissance dans les mouvements dynamiques",
      "Améliorer la technique de crochetage",
      "Bon équilibre sur les prises difficiles"
    ]
  },
  {
    id: 2,
    date: "12 février 2026",
    duration: "38 min",
    grade: "V4-V6",
    overall: 7.8,
    power: 7.8,
    technique: 8.1,
    endurance: 7.5,
    balance: 8.0,
    insights: [
      "Technique de positionnement améliorée",
      "Augmenter l'endurance sur les voies longues",
      "Bonne gestion du rythme"
    ]
  },
  {
    id: 3,
    date: "8 février 2026",
    duration: "52 min",
    grade: "V5-V6",
    overall: 7.5,
    power: 7.0,
    technique: 8.2,
    endurance: 7.8,
    balance: 7.5,
    insights: [
      "Excellente lecture de voie",
      "Renforcer la puissance explosive",
      "Attention à la fatigue en fin de séance"
    ]
  },
  {
    id: 4,
    date: "5 février 2026",
    duration: "41 min",
    grade: "V4-V5",
    overall: 7.2,
    power: 6.8,
    technique: 7.5,
    endurance: 7.6,
    balance: 7.0,
    insights: [
      "Bonne progression sur les prises réglettes",
      "Travailler les mouvements de compression",
      "Améliorer la récupération entre les essais"
    ]
  }
];

export default function Stats() {
  const [selectedVideo, setSelectedVideo] = useState<VideoStat | null>(null);

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-6 pt-8 pb-6">
        <h1 className="text-2xl text-white mb-2">Statistiques</h1>
        <p className="text-gray-400 text-sm">
          Analyse détaillée de vos performances
        </p>
      </div>

      <div className="px-6 space-y-6 pb-6">
        {/* Overall Progress */}
        <div className="bg-gradient-to-br from-cyan-500/20 to-blue-500/20 backdrop-blur-sm border border-cyan-500/30 rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-gray-300 text-sm mb-1">Score Global Moyen</p>
              <p className="text-4xl text-white">7.75</p>
            </div>
            <div className="flex items-center gap-2 bg-green-500/20 text-green-400 px-3 py-2 rounded-lg">
              <TrendingUp className="w-4 h-4" />
              <span className="text-sm">+0.4</span>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <p className="text-gray-400">Puissance</p>
              <p className="text-white">7.53</p>
            </div>
            <div>
              <p className="text-gray-400">Technique</p>
              <p className="text-white">7.75</p>
            </div>
            <div>
              <p className="text-gray-400">Endurance</p>
              <p className="text-white">7.73</p>
            </div>
            <div>
              <p className="text-gray-400">Équilibre</p>
              <p className="text-white">7.83</p>
            </div>
          </div>
        </div>

        {/* Video Stats List */}
        <div>
          <h2 className="text-xl text-white mb-4">Historique des Sessions</h2>
          <div className="space-y-3">
            {mockStats.map((stat) => (
              <button
                key={stat.id}
                onClick={() => setSelectedVideo(selectedVideo?.id === stat.id ? null : stat)}
                className="w-full text-left bg-gray-800/50 backdrop-blur-sm border border-gray-700 hover:border-cyan-500/50 rounded-xl p-4 transition-all"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start gap-3">
                    <div className="bg-cyan-500/20 rounded-lg p-2 mt-1">
                      <Video className="w-5 h-5 text-cyan-400" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <Calendar className="w-4 h-4 text-gray-400" />
                        <p className="text-white text-sm">{stat.date}</p>
                      </div>
                      <div className="flex items-center gap-3 text-xs text-gray-400">
                        <span>{stat.duration}</span>
                        <span>•</span>
                        <div className="flex items-center gap-1">
                          <Award className="w-3 h-3" />
                          <span>{stat.grade}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl text-white">{stat.overall}</p>
                    <p className="text-gray-400 text-xs">Score</p>
                  </div>
                </div>

                {selectedVideo?.id === stat.id && (
                  <div className="mt-4 pt-4 border-t border-gray-700 space-y-4">
                    {/* Detailed Metrics */}
                    <div className="grid grid-cols-2 gap-3">
                      <div className="bg-gray-900/50 rounded-lg p-3">
                        <p className="text-gray-400 text-xs mb-1">Puissance</p>
                        <div className="flex items-center justify-between">
                          <p className="text-white text-lg">{stat.power}</p>
                          <div className="w-16 h-2 bg-gray-700 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-cyan-500 to-blue-500"
                              style={{ width: `${stat.power * 10}%` }}
                            />
                          </div>
                        </div>
                      </div>
                      
                      <div className="bg-gray-900/50 rounded-lg p-3">
                        <p className="text-gray-400 text-xs mb-1">Technique</p>
                        <div className="flex items-center justify-between">
                          <p className="text-white text-lg">{stat.technique}</p>
                          <div className="w-16 h-2 bg-gray-700 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-green-500 to-emerald-500"
                              style={{ width: `${stat.technique * 10}%` }}
                            />
                          </div>
                        </div>
                      </div>
                      
                      <div className="bg-gray-900/50 rounded-lg p-3">
                        <p className="text-gray-400 text-xs mb-1">Endurance</p>
                        <div className="flex items-center justify-between">
                          <p className="text-white text-lg">{stat.endurance}</p>
                          <div className="w-16 h-2 bg-gray-700 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-orange-500 to-red-500"
                              style={{ width: `${stat.endurance * 10}%` }}
                            />
                          </div>
                        </div>
                      </div>
                      
                      <div className="bg-gray-900/50 rounded-lg p-3">
                        <p className="text-gray-400 text-xs mb-1">Équilibre</p>
                        <div className="flex items-center justify-between">
                          <p className="text-white text-lg">{stat.balance}</p>
                          <div className="w-16 h-2 bg-gray-700 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-purple-500 to-pink-500"
                              style={{ width: `${stat.balance * 10}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* AI Insights */}
                    <div className="bg-gradient-to-r from-cyan-500/10 to-blue-500/10 border border-cyan-500/30 rounded-lg p-3">
                      <p className="text-cyan-400 text-sm mb-2 flex items-center gap-2">
                        <span>🤖</span>
                        <span>Analyse IA</span>
                      </p>
                      <ul className="space-y-1">
                        {stat.insights.map((insight, idx) => (
                          <li key={idx} className="text-gray-300 text-xs flex items-start gap-2">
                            <span className="text-cyan-400 mt-0.5">•</span>
                            <span>{insight}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
