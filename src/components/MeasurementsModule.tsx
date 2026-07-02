import React, { useState } from 'react';
import { Measurement } from '../types';
import { Search, Plus, Calendar, Compass, MapPin, CheckCircle, Clock, Trash2, Info, Check, Sparkles, Flame, Droplets, Zap, Wind, HelpCircle, ShieldAlert } from 'lucide-react';

interface MeasurementsModuleProps {
  measurements: Measurement[];
  onAddMeasurement: (item: Measurement) => void;
  onUpdateMeasurement: (item: Measurement) => void;
  onShowToast: (msg: string) => void;
}

export const CABINET_OBSTACLES = [
  { id: 'gas_pipe', label: 'Газ құбыры', desc: 'Газ пеші мен құбырдың шығу орны', icon: Flame, color: 'border-amber-200 bg-amber-50 text-amber-800 dark:bg-amber-950/20 dark:border-amber-900/40 dark:text-amber-400' },
  { id: 'water_sewer', label: 'Су / Канализация', desc: 'Сорғыш пен раковина суы', icon: Droplets, color: 'border-blue-200 bg-blue-50 text-blue-800 dark:bg-blue-950/20 dark:border-blue-900/40 dark:text-blue-400' },
  { id: 'sockets', label: 'Розеткалар / Тоқ', desc: 'Тұрмыстық техникаға арналған розеткалар', icon: Zap, color: 'border-purple-200 bg-purple-50 text-purple-800 dark:bg-purple-950/20 dark:border-purple-900/40 dark:text-purple-400' },
  { id: 'radiator', label: 'Батарея радиаторы', desc: 'Жылу радиаторы және құбырлары', icon: ShieldAlert, color: 'border-rose-200 bg-rose-50 text-rose-800 dark:bg-rose-950/20 dark:border-rose-900/40 dark:text-rose-400' },
  { id: 'window_sill', label: 'Терезе алды тақтасы', desc: 'Столешницамен түйісетін жер', icon: Info, color: 'border-emerald-200 bg-emerald-50 text-emerald-800 dark:bg-emerald-950/20 dark:border-emerald-900/40 dark:text-emerald-400' },
  { id: 'ventilation', label: 'Вентиляция шахтасы', desc: 'Вытяжка құбыры өтетін жол', icon: Wind, color: 'border-indigo-200 bg-indigo-50 text-indigo-800 dark:bg-indigo-950/20 dark:border-indigo-900/40 dark:text-indigo-400' },
];

export default function MeasurementsModule({ measurements, onAddMeasurement, onUpdateMeasurement, onShowToast }: MeasurementsModuleProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  
  // Form State
  const [clientName, setClientName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [date, setDate] = useState('');
  const [roomType, setRoomType] = useState('Ас үй (Кухня)');
  const [width, setWidth] = useState('');
  const [depth, setDepth] = useState('');
  const [height, setHeight] = useState('');
  const [notes, setNotes] = useState('');
  const [obstacles, setObstacles] = useState<string[]>([]);
  const [angle90, setAngle90] = useState<boolean>(true);

  const toggleObstacle = (obsId: string) => {
    if (obstacles.includes(obsId)) {
      setObstacles(obstacles.filter(o => o !== obsId));
    } else {
      setObstacles([...obstacles, obsId]);
    }
  };

  const filtered = measurements.filter(m => 
    m.clientName.toLowerCase().includes(searchTerm.toLowerCase()) || 
    m.phone.includes(searchTerm) || 
    m.address.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientName || !phone || !address || !date) {
      onShowToast('Міндетті өрістерді толтырыңыз');
      return;
    }

    const newMea: Measurement = {
      id: `MEA-${Math.floor(100 + Math.random() * 900)}`,
      clientName: clientName.trim(),
      phone: phone.trim(),
      address: address.trim(),
      date: date,
      status: 'pending',
      notes: notes.trim(),
      roomType: roomType,
      width: width ? Number(width) : undefined,
      depth: depth ? Number(depth) : undefined,
      height: height ? Number(height) : undefined,
      obstacles: obstacles,
      angle90: angle90,
    };

    onAddMeasurement(newMea);
    onShowToast('Өлшеу (замер) кестесіне сәтті қосылды!');
    setShowForm(false);
    resetForm();
  };

  const resetForm = () => {
    setClientName('');
    setPhone('');
    setAddress('');
    setDate('');
    setRoomType('Ас үй (Кухня)');
    setWidth('');
    setDepth('');
    setHeight('');
    setNotes('');
    setObstacles([]);
    setAngle90(true);
  };

  const toggleStatus = (mea: Measurement) => {
    const updatedStatus = mea.status === 'pending' ? 'completed' : 'pending';
    onUpdateMeasurement({
      ...mea,
      status: updatedStatus
    });
    onShowToast(`Өлшеу статусы "${updatedStatus === 'completed' ? 'Аяқталды' : 'Күтуде'}" деп өзгертілді`);
  };

  return (
    <div className="space-y-6">
      
      {/* Title block */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Замер базасы (Технолог кестесі)</h2>
          <p className="text-xs text-slate-500">Жиһаз жасамас бұрын бөлменің нақты өлшемін тіркеу</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-teal-600 hover:bg-teal-700 text-white font-medium text-sm px-4 py-2.5 rounded-xl transition-all flex items-center gap-1.5 cursor-pointer shadow-sm active:scale-98"
        >
          <Compass className="w-4 h-4" />
          Жаңа өлшеу қосу
        </button>
      </div>

      {/* Form modal */}
      {showForm && (
        <form onSubmit={handleSubmit} className="bg-white rounded-3xl p-6 border border-slate-100 shadow-brand grid grid-cols-1 lg:grid-cols-3 gap-6 animate-fadeIn">
          <div className="col-span-1 lg:col-span-3 pb-3 border-b border-slate-100 flex justify-between items-center">
            <div className="flex items-center gap-2">
              <Compass className="w-5 h-5 text-teal-600 animate-spin-slow" />
              <div>
                <h3 className="font-bold text-slate-800 text-sm">Жаңа замерге өтініш & Техникалық карта толтыру</h3>
                <p className="text-[10px] text-slate-400">Өлшеу кезіндегі кедергілерді және бұрыштарды тіркеңіз</p>
              </div>
            </div>
            <button type="button" onClick={() => setShowForm(false)} className="px-2.5 py-1 text-slate-400 hover:text-slate-600 hover:bg-slate-50 border border-slate-200/60 rounded-xl text-xxs transition cursor-pointer">Болдырмау</button>
          </div>

          {/* Left Column: Client & Address Details */}
          <div className="space-y-3 col-span-1">
            <span className="text-xs font-bold text-slate-700 block border-l-2 border-teal-500 pl-2">1. Клиент және мекенжай</span>
            
            <div className="space-y-1">
              <label className="text-[10px] font-semibold text-slate-500">Клиент аты *</label>
              <input 
                type="text" 
                placeholder="Әлия Мұратова" 
                value={clientName}
                onChange={(e) => setClientName(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
                required
              />
            </div>

            <div className="space-y-1">
              <label className="text-[10px] font-semibold text-slate-500">Телефон *</label>
              <input 
                type="tel" 
                placeholder="+7 701 123 4567" 
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
                required
              />
            </div>

            <div className="space-y-1">
              <label className="text-[10px] font-semibold text-slate-500">Замер Күні *</label>
              <input 
                type="date" 
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs text-slate-800 focus:outline-none cursor-pointer"
                required
              />
            </div>

            <div className="space-y-1">
              <label className="text-[10px] font-semibold text-slate-500">Мекенжай *</label>
              <input 
                type="text" 
                placeholder="Жароков көшесі, 24-үй, 5-пәтер" 
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
                required
              />
            </div>
          </div>

          {/* Middle Column: Dimensions & Obstacle Checklist */}
          <div className="space-y-3 col-span-1">
            <span className="text-xs font-bold text-slate-700 block border-l-2 border-teal-500 pl-2">2. Технологиялық өлшемдер</span>
            
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1 col-span-2">
                <label className="text-[10px] font-semibold text-slate-500">Жиһаз / Бөлме түрі</label>
                <select
                  value={roomType}
                  onChange={(e) => setRoomType(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-2.5 py-1.5 text-xs text-slate-800 focus:outline-none cursor-pointer"
                >
                  <option value="Ас үй (Кухня)">Ас үй (Кухня)</option>
                  <option value="Шкаф-купе">Шкаф-купе</option>
                  <option value="Гардероб бөлмесі">Гардероб бөлмесі</option>
                  <option value="Кіреберіс (Прихожая)">Кіреберіс (Прихожая)</option>
                  <option value="ТВ консоль / Комод">ТВ консоль / Комод</option>
                  <option value="Басқа жеке жоба">Басқа жеке жоба</option>
                </select>
              </div>

              <div className="col-span-2 space-y-1">
                <label className="text-[10px] font-semibold text-slate-500 block">Өлшемдер (Ені х Тереңдігі х Биіктігі, см)</label>
                <div className="flex gap-1">
                  <input 
                    type="number" 
                    placeholder="Ені (W)" 
                    value={width}
                    onChange={(e) => setWidth(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 text-center text-xs text-slate-800 focus:outline-none font-mono"
                  />
                  <input 
                    type="number" 
                    placeholder="Терең (D)" 
                    value={depth}
                    onChange={(e) => setDepth(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 text-center text-xs text-slate-800 focus:outline-none font-mono"
                  />
                  <input 
                    type="number" 
                    placeholder="Биік (H)" 
                    value={height}
                    onChange={(e) => setHeight(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 text-center text-xs text-slate-800 focus:outline-none font-mono"
                  />
                </div>
              </div>

              {/* 90 degree Angle check */}
              <div className="col-span-2 pt-1">
                <label className="text-[10px] font-semibold text-slate-500 block mb-1">Бұрыштарды тексеру (90° градус)</label>
                <button
                  type="button"
                  onClick={() => setAngle90(!angle90)}
                  className={`w-full py-2 px-3 border rounded-xl text-xxs font-bold transition flex items-center justify-center gap-1.5 cursor-pointer ${
                    angle90 
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-700' 
                      : 'bg-rose-500/10 border-rose-500/30 text-rose-700'
                  }`}
                >
                  <span className={`w-2 h-2 rounded-full ${angle90 ? 'bg-emerald-500' : 'bg-rose-500 animate-ping'}`} />
                  {angle90 ? 'Бұрыштар түзу (90° градус тегіс)' : 'Бұрыштар қисық (Қондыру қиын / зазор қажет)'}
                </button>
              </div>
            </div>
          </div>

          {/* Right Column: Interactive Room Map / Hotspots */}
          <div className="space-y-3 col-span-1">
            <span className="text-xs font-bold text-slate-700 block border-l-2 border-teal-500 pl-2">3. Интерактивті қабырға сызбасы</span>
            
            <div className="relative border border-slate-200 bg-slate-950 rounded-2xl h-44 w-full overflow-hidden shadow-inner flex flex-col items-center justify-center">
              {/* Grid blueprint lines */}
              <div className="absolute inset-0 grid grid-cols-6 grid-rows-4 opacity-[0.05] pointer-events-none">
                {Array.from({ length: 24 }).map((_, i) => (
                  <div key={i} className="border-r border-b border-teal-400"></div>
                ))}
              </div>

              {/* 1. Gas pipe (left-mid) */}
              <button
                type="button"
                onClick={() => toggleObstacle('gas_pipe')}
                className={`absolute left-4 top-14 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('gas_pipe') 
                    ? 'bg-amber-500 border-amber-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Газ құбыры"
              >
                <Flame className="w-3.5 h-3.5" />
              </button>

              {/* 2. Water / Sewer (bottom-mid) */}
              <button
                type="button"
                onClick={() => toggleObstacle('water_sewer')}
                className={`absolute left-1/3 bottom-3 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('water_sewer') 
                    ? 'bg-blue-500 border-blue-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Су / Канализация"
              >
                <Droplets className="w-3.5 h-3.5" />
              </button>

              {/* 3. Sockets (middle-right) */}
              <button
                type="button"
                onClick={() => toggleObstacle('sockets')}
                className={`absolute right-1/4 top-1/2 -translate-y-1/2 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('sockets') 
                    ? 'bg-purple-500 border-purple-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Розеткалар"
              >
                <Zap className="w-3.5 h-3.5" />
              </button>

              {/* 4. Ventilation (top-right) */}
              <button
                type="button"
                onClick={() => toggleObstacle('ventilation')}
                className={`absolute right-4 top-4 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('ventilation') 
                    ? 'bg-indigo-500 border-indigo-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Вентиляция шахтасы"
              >
                <Wind className="w-3.5 h-3.5" />
              </button>

              {/* 5. Radiator (bottom-right) */}
              <button
                type="button"
                onClick={() => toggleObstacle('radiator')}
                className={`absolute right-4 bottom-4 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('radiator') 
                    ? 'bg-rose-500 border-rose-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Жылу батареясы"
              >
                <ShieldAlert className="w-3.5 h-3.5" />
              </button>

              {/* 6. Window Sill (middle-left) */}
              <button
                type="button"
                onClick={() => toggleObstacle('window_sill')}
                className={`absolute left-1/4 top-4 p-2 rounded-full border transition-all cursor-pointer ${
                  obstacles.includes('window_sill') 
                    ? 'bg-emerald-500 border-emerald-400 text-white scale-110 shadow-lg' 
                    : 'bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700'
                }`}
                title="Терезе алды"
              >
                <Info className="w-3.5 h-3.5" />
              </button>

              <span className="text-[8px] text-slate-600 font-bold uppercase tracking-widest">Батырмаларды басып таңдаңыз</span>
              <span className="absolute bottom-2 left-2 text-[7px] text-slate-500 font-mono">еден (пол)</span>
              <span className="absolute top-2 left-2 text-[7px] text-slate-500 font-mono">төбе (потолок)</span>
            </div>

            {/* Quick check badges shown under */}
            <div className="flex flex-wrap gap-1">
              {CABINET_OBSTACLES.map(obs => {
                const active = obstacles.includes(obs.id);
                const Icon = obs.icon;
                return (
                  <button
                    key={obs.id}
                    type="button"
                    onClick={() => toggleObstacle(obs.id)}
                    className={`px-2 py-1 rounded-lg text-[9px] border transition flex items-center gap-1 cursor-pointer ${
                      active 
                        ? 'bg-teal-500 border-teal-400 text-slate-950 font-bold' 
                        : 'bg-slate-50 border-slate-200 text-slate-500'
                    }`}
                  >
                    <Icon className="w-2.5 h-2.5" />
                    {obs.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Text notes & Submit */}
          <div className="col-span-1 lg:col-span-3 space-y-1.5 pt-2 border-t border-slate-100">
            <label className="text-[10px] font-semibold text-slate-500">Замер технологының қосымша ескертулері</label>
            <textarea 
              rows={2}
              placeholder="Мысалы: Оң жақ қабырға гипсокартон, анкерлік болт ұстамайды. Газ санауышын шкаф ішіне жасыру қажет..." 
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
            />
          </div>

          <div className="col-span-1 lg:col-span-3 flex justify-end gap-2">
            <button
              type="submit"
              className="bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs px-6 py-2.5 rounded-xl transition cursor-pointer flex items-center gap-1 active:scale-98"
            >
              <Check className="w-4 h-4" />
              Өлшеу Картасын Тіркеу
            </button>
          </div>
        </form>
      )}

      {/* Search Input */}
      <div className="relative">
        <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
        <input 
          type="text" 
          placeholder="Клиент есімі, мекенжайы немесе телефоны арқылы іздеу..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
        />
      </div>

      {/* Measurements Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.map(mea => (
          <div key={mea.id} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm flex flex-col justify-between hover:border-slate-200 transition">
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-xxs font-mono bg-slate-100 text-slate-500 px-2 py-0.5 rounded font-black">
                  {mea.id}
                </span>
                <span className={`px-2.5 py-0.5 rounded-full text-xxs font-semibold uppercase tracking-wider ${
                  mea.status === 'completed' ? 'bg-emerald-50 border border-emerald-100 text-emerald-800' : 'bg-amber-50 border border-amber-100 text-amber-800'
                }`}>
                  {mea.status === 'completed' ? 'Өлшенді (Аяқталды)' : 'Өлшеу күтуде'}
                </span>
              </div>

              <div>
                <h3 className="font-bold text-slate-800 text-base">{mea.clientName}</h3>
                <p className="text-xs text-slate-500 font-mono">{mea.phone}</p>
                <div className="flex items-center gap-1.5 text-xs text-slate-600 mt-2">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" />
                  <span>{mea.address}</span>
                </div>
                <div className="flex items-center gap-1.5 text-xs text-slate-600 mt-1">
                  <Calendar className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-semibold text-slate-700">Замер Күні: {mea.date}</span>
                </div>
              </div>

              {/* Dimensions specs box */}
              {(mea.width || mea.depth || mea.height) && (
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-xs text-slate-700 space-y-1">
                  <p className="font-semibold text-xxs text-slate-400 uppercase tracking-widest">Өлшенген өлшемдер ({mea.roomType}):</p>
                  <div className="grid grid-cols-3 text-center gap-1 font-mono text-xs mt-1.5">
                    <div className="bg-white rounded p-1 border border-slate-100">
                      <span className="text-xxs text-slate-400 block uppercase font-sans">Ені</span>
                      <strong>{mea.width || '—'} см</strong>
                    </div>
                    <div className="bg-white rounded p-1 border border-slate-100">
                      <span className="text-xxs text-slate-400 block uppercase font-sans">Тереңдігі</span>
                      <strong>{mea.depth || '—'} см</strong>
                    </div>
                    <div className="bg-white rounded p-1 border border-slate-100">
                      <span className="text-xxs text-slate-400 block uppercase font-sans">Биіктігі</span>
                      <strong>{mea.height || '—'} см</strong>
                    </div>
                  </div>
                </div>
              )}

              {/* Corner angle & Obstacle warning badges */}
              <div className="space-y-1.5">
                {/* 90 degree status */}
                <div className={`px-2.5 py-1 rounded-xl text-[10px] font-bold flex items-center gap-1.5 border ${
                  mea.angle90 === false 
                    ? 'bg-rose-50 border-rose-100 text-rose-700' 
                    : 'bg-emerald-50 border-emerald-100 text-emerald-700'
                }`}>
                  <span className={`w-1.5 h-1.5 rounded-full ${mea.angle90 === false ? 'bg-rose-500 animate-pulse' : 'bg-emerald-500'}`} />
                  <span>
                    {mea.angle90 === false 
                      ? 'Қабырға бұрышы 90° ЕМЕС (монтаж кезінде қиындық бар)' 
                      : 'Қабырға бұрыштары: 90° градус тегіс'}
                  </span>
                </div>

                {/* Checked obstacles list */}
                {mea.obstacles && mea.obstacles.length > 0 && (
                  <div className="space-y-1 pt-1">
                    <p className="text-[9px] font-bold text-slate-400 uppercase tracking-wider">Анықталған кедергілер:</p>
                    <div className="flex flex-wrap gap-1">
                      {mea.obstacles.map(obsId => {
                        const obstacle = CABINET_OBSTACLES.find(o => o.id === obsId);
                        if (!obstacle) return null;
                        const Icon = obstacle.icon;
                        return (
                          <span 
                            key={obsId} 
                            className={`px-2 py-0.5 rounded-lg text-[9px] font-semibold border flex items-center gap-1 ${obstacle.color}`}
                          >
                            <Icon className="w-2.5 h-2.5" />
                            {obstacle.label}
                          </span>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>

              {mea.notes && (
                <p className="bg-teal-50/30 p-2.5 rounded-xl text-slate-600 italic text-xxs border border-teal-50/50">
                  "Ескертпе: {mea.notes}"
                </p>
              )}
            </div>

            <div className="flex gap-2 border-t border-slate-50 pt-3 mt-4">
              <button
                onClick={() => toggleStatus(mea)}
                className={`flex-1 text-center py-1.5 rounded-lg text-xs font-bold transition cursor-pointer flex items-center justify-center gap-1.5 ${
                  mea.status === 'completed' 
                    ? 'bg-slate-100 hover:bg-amber-50 text-slate-600 hover:text-amber-700' 
                    : 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700'
                }`}
              >
                {mea.status === 'completed' ? (
                  <>Күтуде деп өзгерту</>
                ) : (
                  <>
                    <CheckCircle className="w-3.5 h-3.5" />
                    Өлшеу аяқталды деп белгілеу
                  </>
                )}
              </button>
            </div>
          </div>
        ))}
      </div>

    </div>
  );
}
