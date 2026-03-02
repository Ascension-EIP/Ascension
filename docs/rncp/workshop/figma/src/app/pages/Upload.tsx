import { useState, useRef } from "react";
import { Video, Upload as UploadIcon, Camera, Check, Loader2 } from "lucide-react";

export default function Upload() {
  const [isUploading, setIsUploading] = useState(false);
  const [uploadComplete, setUploadComplete] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setUploadComplete(false);
    }
  };

  const handleUpload = () => {
    if (!selectedFile) return;
    
    setIsUploading(true);
    // Simulate upload and AI analysis
    setTimeout(() => {
      setIsUploading(false);
      setUploadComplete(true);
      setTimeout(() => {
        setUploadComplete(false);
        setSelectedFile(null);
      }, 2000);
    }, 3000);
  };

  return (
    <div className="min-h-full">
      {/* Header */}
      <div className="px-6 pt-8 pb-6">
        <h1 className="text-2xl text-white mb-2">Uploader une vidéo</h1>
        <p className="text-gray-400 text-sm">
          Filmez ou importez votre session pour une analyse détaillée
        </p>
      </div>

      <div className="px-6 space-y-6">
        {/* Upload Area */}
        <div className="space-y-4">
          <button
            onClick={() => fileInputRef.current?.click()}
            className="w-full bg-gradient-to-br from-cyan-500/20 to-blue-500/20 backdrop-blur-sm border-2 border-dashed border-cyan-500/50 hover:border-cyan-400 rounded-2xl p-8 transition-all"
          >
            <div className="flex flex-col items-center gap-3">
              <div className="bg-cyan-500/20 rounded-full p-4">
                <UploadIcon className="w-8 h-8 text-cyan-400" />
              </div>
              <div className="text-center">
                <p className="text-white mb-1">Choisir une vidéo</p>
                <p className="text-gray-400 text-sm">MP4, MOV jusqu'à 500 MB</p>
              </div>
            </div>
          </button>
          
          <input
            ref={fileInputRef}
            type="file"
            accept="video/*"
            onChange={handleFileSelect}
            className="hidden"
          />

          {/* Camera Button */}
          <button className="w-full bg-gradient-to-br from-purple-500/20 to-pink-500/20 backdrop-blur-sm border-2 border-dashed border-purple-500/50 hover:border-purple-400 rounded-2xl p-8 transition-all">
            <div className="flex flex-col items-center gap-3">
              <div className="bg-purple-500/20 rounded-full p-4">
                <Camera className="w-8 h-8 text-purple-400" />
              </div>
              <div className="text-center">
                <p className="text-white mb-1">Filmer maintenant</p>
                <p className="text-gray-400 text-sm">Capturer directement depuis la caméra</p>
              </div>
            </div>
          </button>
        </div>

        {/* Selected File Preview */}
        {selectedFile && (
          <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-cyan-500/20 rounded-lg p-2">
                <Video className="w-5 h-5 text-cyan-400" />
              </div>
              <div className="flex-1">
                <p className="text-white text-sm">{selectedFile.name}</p>
                <p className="text-gray-400 text-xs">
                  {(selectedFile.size / (1024 * 1024)).toFixed(2)} MB
                </p>
              </div>
              {uploadComplete && (
                <Check className="w-6 h-6 text-green-400" />
              )}
            </div>
            
            {!uploadComplete && (
              <button
                onClick={handleUpload}
                disabled={isUploading}
                className="w-full bg-gradient-to-r from-cyan-500 to-blue-500 hover:from-cyan-600 hover:to-blue-600 disabled:opacity-50 disabled:cursor-not-allowed text-white py-3 rounded-xl transition-all flex items-center justify-center gap-2"
              >
                {isUploading ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>Analyse en cours...</span>
                  </>
                ) : (
                  <>
                    <UploadIcon className="w-5 h-5" />
                    <span>Analyser avec l'IA</span>
                  </>
                )}
              </button>
            )}
            
            {uploadComplete && (
              <div className="bg-green-500/20 border border-green-500/30 rounded-xl p-4 text-center">
                <p className="text-green-400">✓ Analyse terminée !</p>
                <p className="text-gray-300 text-sm mt-1">
                  Consultez vos stats dans l'onglet Stats
                </p>
              </div>
            )}
          </div>
        )}

        {/* Info Section */}
        <div className="bg-gray-800/30 border border-gray-700/50 rounded-xl p-4">
          <h3 className="text-white mb-3 flex items-center gap-2">
            <span className="text-cyan-400">🤖</span>
            Ce que l'IA analyse
          </h3>
          <ul className="space-y-2 text-sm text-gray-300">
            <li className="flex items-start gap-2">
              <span className="text-cyan-400 mt-1">•</span>
              <span>Position du corps et centre de gravité</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-cyan-400 mt-1">•</span>
              <span>Puissance et fluidité des mouvements</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-cyan-400 mt-1">•</span>
              <span>Technique de préhension et positionnement des pieds</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-cyan-400 mt-1">•</span>
              <span>Endurance et temps de repos</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-cyan-400 mt-1">•</span>
              <span>Recommandations personnalisées</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
