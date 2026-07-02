import { useState } from 'react';
import { Employee } from '../types';
import { Search, Trophy, Gift, Phone, CheckCircle2, UserCheck, Star } from 'lucide-react';

interface EmployeesModuleProps {
  employees: Employee[];
  onRewardBonus: (employeeId: string, amount: number) => void;
  onShowToast: (msg: string) => void;
}

const ROLE_KAZAKH = {
  carpenter: 'Ағаш шебері (Каркасші)',
  upholsterer: 'Тігін-Қаптаушы шебер',
  designer: 'Жобалаушы Дизайнер',
  measurer: 'Технолог-Замерщик',
  courier: 'Курьер / Жеткізуші',
  manager: 'Менеджер'
};

export default function EmployeesModule({ employees, onRewardBonus, onShowToast }: EmployeesModuleProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [showBonusForm, setShowBonusForm] = useState<string | null>(null);
  const [bonusAmount, setBonusAmount] = useState('');
  const [bonusReason, setBonusReason] = useState('Тамаша сапалы жұмыс үшін');

  const filteredEmployees = employees.filter(emp => 
    emp.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    ROLE_KAZAKH[emp.role].toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleReward = (empId: string) => {
    const value = Number(bonusAmount);
    if (isNaN(value) || value <= 0) {
      onShowToast('Дұрыс соманы жазыңыз');
      return;
    }

    onRewardBonus(empId, value);
    onShowToast(`Қызметкерге ${value.toLocaleString()} ₸ бонус сәтті есептелді!`);
    setBonusAmount('');
    setShowBonusForm(null);
  };

  return (
    <div className="space-y-6">
      
      {/* Title block */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Қызметкерлер мен Бонус жүйесі</h2>
          <p className="text-xs text-slate-500">Шеберхана қызметкерлерінің белсенділігі мен сыйақы теңгерімін бақылау</p>
        </div>
      </div>

      {/* Top statistics banners */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-teal-50 rounded-xl text-teal-600">
            <UserCheck className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Жалпы шеберлер</span>
            <h3 className="text-lg font-bold text-slate-800">{employees.length} маман</h3>
          </div>
        </div>

        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-50 rounded-xl text-amber-600">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Аяқталған тапсырыс саны</span>
            <h3 className="text-lg font-bold text-slate-800">
              {employees.reduce((sum, e) => sum + e.completedTasks, 0)} бұйым жасалды
            </h3>
          </div>
        </div>

        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-rose-50 rounded-xl text-rose-600">
            <Trophy className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Төленген бонустар</span>
            <h3 className="text-lg font-black text-rose-600">
              {employees.reduce((sum, e) => sum + e.totalBonuses, 0).toLocaleString()} ₸
            </h3>
          </div>
        </div>
      </div>

      {/* Search Input */}
      <div className="relative">
        <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
        <input 
          type="text" 
          placeholder="Шебер есімін немесе лауазымын іздеу..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
        />
      </div>

      {/* Employees Grid list */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredEmployees.map((emp) => (
          <div key={emp.id} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm flex flex-col justify-between hover:border-slate-200 transition">
            
            <div className="space-y-4">
              
              {/* Profile Card Header */}
              <div className="flex justify-between items-start">
                <div className="flex gap-3 items-center">
                  <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600 border border-slate-200 uppercase">
                    {emp.name.slice(0, 2)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 text-base">{emp.name}</h3>
                    <span className="text-xxs font-semibold text-teal-600 uppercase tracking-wider bg-teal-50 px-2 py-0.5 rounded">
                      {ROLE_KAZAKH[emp.role]}
                    </span>
                  </div>
                </div>

                <div className="flex flex-col items-end">
                  <span className="text-3xs uppercase text-slate-400 font-bold">Бонус теңгерімі</span>
                  <span className="font-black text-rose-600 text-sm">{emp.totalBonuses.toLocaleString()} ₸</span>
                </div>
              </div>

              {/* Stats and Contacts */}
              <div className="grid grid-cols-3 gap-2 text-center py-2.5 bg-slate-50 rounded-xl border border-slate-100/80">
                <div>
                  <span className="text-4xs uppercase font-bold text-slate-400 block">Белсенді жұмыс</span>
                  <strong className="text-slate-800 text-sm font-bold font-mono">{emp.activeTasks}</strong>
                </div>
                <div>
                  <span className="text-4xs uppercase font-bold text-slate-400 block">Біткен жұмыс</span>
                  <strong className="text-slate-800 text-sm font-bold font-mono">{emp.completedTasks}</strong>
                </div>
                <div>
                  <span className="text-4xs uppercase font-bold text-slate-400 block">Табысы (Айына)</span>
                  <strong className="text-emerald-600 text-sm font-black font-mono">+{((emp.completedTasks * 18000) + emp.totalBonuses).toLocaleString()} ₸</strong>
                </div>
              </div>

              <div className="flex items-center gap-2 text-xs text-slate-500">
                <Phone className="w-3.5 h-3.5 text-slate-400" />
                <span className="font-mono">{emp.phone}</span>
              </div>

            </div>

            {/* Reward Bonus Subform */}
            <div className="border-t border-slate-50 pt-3.5 mt-4">
              {showBonusForm === emp.id ? (
                <div className="bg-rose-50/50 border border-rose-100 rounded-xl p-3 space-y-3">
                  <div className="flex justify-between items-center text-xs font-bold text-rose-800">
                    <span>Сыйлықақы беру (Бонус)</span>
                    <button onClick={() => setShowBonusForm(null)} className="text-3xs text-slate-400">Жабу</button>
                  </div>
                  
                  <div className="flex gap-2">
                    <input
                      type="number"
                      placeholder="Сомасы (₸)... мысалы 15000"
                      value={bonusAmount}
                      onChange={(e) => setBonusAmount(e.target.value)}
                      className="bg-white border border-slate-200 rounded-xl px-3 py-1.5 text-xs text-slate-800 focus:outline-none flex-1 font-mono font-bold"
                    />
                    <button
                      onClick={() => handleReward(emp.id)}
                      className="bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs px-4 py-1.5 rounded-xl transition cursor-pointer"
                    >
                      Сыйлау
                    </button>
                  </div>
                  
                  <input
                    type="text"
                    value={bonusReason}
                    onChange={(e) => setBonusReason(e.target.value)}
                    placeholder="Бонус себебі..."
                    className="w-full bg-white border border-slate-200 rounded-lg px-2 py-1 text-3xs text-slate-600 focus:outline-none"
                  />
                </div>
              ) : (
                <button
                  onClick={() => {
                    setShowBonusForm(emp.id);
                    setBonusAmount('');
                  }}
                  className="w-full bg-slate-50 hover:bg-rose-50 hover:text-rose-700 text-slate-600 text-xxs font-black py-2 rounded-xl transition border border-dashed border-slate-200 hover:border-rose-200 cursor-pointer flex justify-center items-center gap-1.5"
                >
                  <Gift className="w-3.5 h-3.5 text-rose-500" />
                  Осы қызметкерге Бонус есептеу
                </button>
              )}
            </div>

          </div>
        ))}
      </div>

    </div>
  );
}
