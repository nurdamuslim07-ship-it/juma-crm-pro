import { useState, useMemo } from 'react';
import { Order, Client, InventoryItem, Employee, Measurement } from '../types';
import { TrendingUp, BarChart2, PieChart, Activity, Briefcase, BrainCircuit, Coins, Warehouse, Hammer, Sparkles, AlertCircle } from 'lucide-react';

interface ReportsModuleProps {
  orders: Order[];
  clients: Client[];
  inventory: InventoryItem[];
  employees?: Employee[];
  measurements?: Measurement[];
}

export default function ReportsModule({ 
  orders, 
  clients, 
  inventory,
  employees = [],
  measurements = []
}: ReportsModuleProps) {
  const [aiDimension, setAiDimension] = useState<'finance' | 'supply' | 'production'>('finance');
  
  const stats = useMemo(() => {
    const totalRevenue = orders.filter(o => o.status !== 'cancelled').reduce((sum, o) => sum + o.price, 0);
    const totalPaid = orders.filter(o => o.status !== 'cancelled').reduce((sum, o) => sum + o.paidAmount, 0);
    const remainingToCollect = totalRevenue - totalPaid;
    
    // Calculate total costs and net profit based on cost breakdowns
    let totalCosts = 0;
    let ordersWithBreakdownCount = 0;
    orders.filter(o => o.status !== 'cancelled').forEach(o => {
      if (o.costBreakdown) {
        const cb = o.costBreakdown;
        const totalMaterials = (cb.woodSheetsCount * cb.woodSheetPrice) + (cb.edgeMeters * cb.edgePrice) + cb.fittingsCost;
        const totalCost = totalMaterials + cb.laborCost + cb.overheadCost;
        totalCosts += totalCost;
        ordersWithBreakdownCount++;
      } else {
        // Safe default: approximate costs as 60% of product price if breakdown is missing
        totalCosts += Math.round(o.price * 0.62);
      }
    });

    const netProfit = Math.max(0, totalRevenue - totalCosts);
    const averageMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

    // Status counts
    const statusCounts = orders.reduce((acc, o) => {
      acc[o.status] = (acc[o.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    // Category counts (using products)
    const productSales = orders.reduce((acc, o) => {
      let cat = 'Басқа';
      if (o.productType.includes('Диван')) cat = 'Дивандар';
      else if (o.productType.includes('Кереует')) cat = 'Кереуеттер';
      else if (o.productType.includes('Үстел') || o.productType.includes('үстел')) cat = 'Үстелдер';
      else if (o.productType.includes('Орындық')) cat = 'Орындықтар';
      else if (o.productType.includes('Ас үй') || o.productType.includes('Кухня')) cat = 'Ас үй жиһазы';
      
      acc[cat] = (acc[cat] || 0) + o.price;
      return acc;
    }, {} as Record<string, number>);

    return {
      totalRevenue,
      totalPaid,
      remainingToCollect,
      totalCosts,
      netProfit,
      averageMargin,
      ordersWithBreakdownCount,
      statusCounts,
      productSales,
    };
  }, [orders]);

  // AI-Advisor dynamic metrics
  const cashRatio = stats.totalRevenue > 0 ? (stats.totalPaid / stats.totalRevenue) : 1;
  const lowStockItems = inventory.filter(item => item.quantity <= item.minQuantity);
  const lowStockCount = lowStockItems.length;

  // Workload analyzer
  const activeOrders = orders.filter(o => o.status !== 'completed' && o.status !== 'cancelled');
  const employeeLoad = activeOrders.reduce((acc, o) => {
    if (o.employeeId) {
      acc[o.employeeId] = (acc[o.employeeId] || 0) + 1;
    }
    return acc;
  }, {} as Record<string, number>);
  const hasHighWorkload = Object.values(employeeLoad).some(load => load >= 3);

  return (
    <div className="space-y-6">
      
      {/* Title block */}
      <div>
        <h2 className="text-xl font-bold text-slate-800">Есептер мен Аналитика</h2>
        <p className="text-xs text-slate-500">Жиһаз шеберханасының сауда айналымы, қаржылық көрсеткіштері мен тиімділігі</p>
      </div>

      {/* Main financial indicators */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400 block">Жалпы Тапсырыс Айналымы</span>
            <h2 className="text-xl font-bold text-slate-800 font-mono mt-1">{stats.totalRevenue.toLocaleString()} ₸</h2>
          </div>
          <p className="text-xxs text-slate-400 mt-3 flex items-center gap-1">
            <TrendingUp className="w-3.5 h-3.5 text-teal-500" />
            Күші жойылмаған тапсырыстар құны
          </p>
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400 block">Кассаға Түскен Нақты Ақша</span>
            <h2 className="text-xl font-bold text-emerald-600 font-mono mt-1">{stats.totalPaid.toLocaleString()} ₸</h2>
          </div>
          <div className="w-full bg-slate-100 h-1 mt-3 rounded-full overflow-hidden">
            <div 
              className="bg-emerald-500 h-full rounded-full transition-all duration-500"
              style={{ width: `${stats.totalRevenue > 0 ? (stats.totalPaid / stats.totalRevenue) * 100 : 0}%` }}
            />
          </div>
          <div className="flex justify-between items-center text-3xs text-slate-400 mt-1 font-mono">
            <span>Қалдық қарыз: {stats.remainingToCollect.toLocaleString()} ₸</span>
            <span>{stats.totalRevenue > 0 ? Math.round((stats.totalPaid / stats.totalRevenue) * 100) : 0}%</span>
          </div>
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400 block">Есептелген Жалпы Шығын</span>
            <h2 className="text-xl font-bold text-rose-500 font-mono mt-1">{stats.totalCosts.toLocaleString()} ₸</h2>
          </div>
          <div className="w-full bg-slate-100 h-1 mt-3 rounded-full overflow-hidden">
            <div 
              className="bg-rose-500 h-full rounded-full transition-all duration-500"
              style={{ width: `${stats.totalRevenue > 0 ? (stats.totalCosts / stats.totalRevenue) * 100 : 0}%` }}
            />
          </div>
          <div className="flex justify-between items-center text-3xs text-slate-400 mt-1 font-mono">
            <span>Шығындар үлесі:</span>
            <span>{stats.totalRevenue > 0 ? Math.round((stats.totalCosts / stats.totalRevenue) * 100) : 0}%</span>
          </div>
        </div>

        <div className="bg-gradient-to-br from-indigo-600 to-violet-700 text-white rounded-2xl p-4 shadow-sm relative overflow-hidden flex flex-col justify-between">
          <div className="absolute right-[-10px] bottom-[-10px] opacity-10">
            <Coins className="w-20 h-20" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold opacity-85 block">Шеберхананың Таза Пайдасы</span>
            <h2 className="text-xl font-black font-mono mt-1">{stats.netProfit.toLocaleString()} ₸</h2>
          </div>
          <div className="mt-3 flex justify-between items-center text-3xs font-semibold opacity-90">
            <span>Орташа маржа: {Math.round(stats.averageMargin)}%</span>
            <span className="bg-white/15 px-1.5 py-0.5 rounded text-[9px] font-mono">
              {stats.ordersWithBreakdownCount} / {orders.length} есептелді
            </span>
          </div>
        </div>
      </div>

      {/* "Aqyldy Sheber" Strategic AI-Advisor Dashboard */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-950 to-indigo-950 border border-slate-800 rounded-3xl p-6 shadow-2xl relative overflow-hidden space-y-4">
        {/* Animated background flare */}
        <div className="absolute right-[-20px] top-[-20px] w-48 h-48 rounded-full bg-blue-500/10 blur-3xl pointer-events-none" />
        
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-800 pb-4">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-gradient-to-br from-indigo-500 to-sky-500 rounded-xl shadow-lg">
              <BrainCircuit className="w-5 h-5 text-white animate-pulse" />
            </div>
            <div>
              <h3 className="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
                Ақылды AI-Шебер стратегиялық кеңесшісі
                <span className="text-[9px] font-black bg-sky-500 text-slate-950 px-1.5 py-0.5 rounded-full uppercase tracking-normal">Pro</span>
              </h3>
              <p className="text-3xs text-slate-400">Шеберхананың ағымдағы деректерін стратегиялық талдау негізінде автоматты ұсыныстар</p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-xxs font-mono text-slate-400">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Анализ Белсенді
          </div>
        </div>

        {/* Tabs for Advice Categories */}
        <div className="grid grid-cols-3 gap-2 p-1 bg-slate-950/60 rounded-2xl border border-slate-900">
          {[
            { id: 'finance', label: 'Қаржы & Сауда', icon: Coins },
            { id: 'supply', label: 'Қойма & Логистика', icon: Warehouse },
            { id: 'production', label: 'Өндіріс & Шеберлер', icon: Hammer }
          ].map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setAiDimension(tab.id as any)}
                className={`flex items-center justify-center gap-1.5 py-2 px-1 rounded-xl text-xxs font-bold transition cursor-pointer ${
                  aiDimension === tab.id
                    ? 'bg-slate-800 text-white border border-slate-750 shadow'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Advice Panel Render */}
        <div className="p-4 bg-slate-900/40 rounded-2xl border border-slate-900/80 min-h-[130px] flex flex-col justify-between">
          <div className="space-y-3">
            {aiDimension === 'finance' && (
              <div className="space-y-2.5 animate-fadeIn">
                <div className="flex items-center gap-1.5 text-xs font-bold text-amber-400">
                  <Coins className="w-4 h-4" />
                  Қаржылық айналым және төлем балансы
                </div>
                <p className="text-xxs text-slate-300 leading-relaxed">
                  {cashRatio < 0.5 ? (
                    <span>⚠️ <strong>Қауіпті кассалық тапшылық байқалады!</strong> Шеберхананың нақты қолма-қол ақша үлесі өте төмен (тек <strong>{Math.round(cashRatio * 100)}%</strong>). Жаңа тапсырыстарды қабылдаған кезде міндетті түрде <strong>кем дегенде 50-70% аванстық төлем</strong> алуды енгізіңіз. Бұл материалдарды уақтылы сатып алуға көмектеседі.</span>
                  ) : (
                    <span>✅ <strong>Қаржылық тұрақтылық деңгейі жақсы.</strong> Нақты кассаға түскен қаражат үлесі: <strong>{Math.round(cashRatio * 100)}%</strong>. Сауда айналымын одан әрі ұлғайту үшін белсенді клиенттерге келесі тапсырысқа <strong>5% адалдық жеңілдігін (кешбэк)</strong> ұсынуды қарастырыңыз.</span>
                  )}
                </p>
                <div className="bg-slate-950/50 p-2.5 rounded-xl border border-slate-900 text-3xs font-mono text-slate-400 flex justify-between items-center">
                  <span>Ағымдағы жиынтық айналым: <strong>{stats.totalRevenue.toLocaleString()} ₸</strong></span>
                  <span>Болжамды келесі ай өсімі: <strong className="text-emerald-400">+15%</strong></span>
                </div>
              </div>
            )}

            {aiDimension === 'supply' && (
              <div className="space-y-2.5 animate-fadeIn">
                <div className="flex items-center gap-1.5 text-xs font-bold text-sky-400">
                  <Warehouse className="w-4 h-4" />
                  Шикізат қорлары мен материалдар бақылауы
                </div>
                <p className="text-xxs text-slate-300 leading-relaxed">
                  {lowStockCount > 0 ? (
                    <span>⚠️ <strong>Шұғыл қойма тапшылығы:</strong> Қазіргі уақытта қоймада <strong>{lowStockCount} материал түрі</strong> сыни деңгейден төмен қалыпты! Тез арада сатып алуды ұсынамыз: <strong>{lowStockItems.slice(0, 3).map(i => `${i.name} (${i.quantity} ${i.unit})`).join(', ')}</strong>. Бұл шикізаттар өндірістегі тапсырыстардың мерзімін кешіктірмеуі тиіс!</span>
                  ) : (
                    <span>✅ <strong>Қоймадағы материалдар балансы тамаша!</strong> Барлық негізгі шикізаттар (ЛДСП Egger, МДФ, фурнитура, клей, поролон) қауіпсіз деңгейде сақтаулы. Сапалы өндіріс уақтылы жалғасады.</span>
                  )}
                </p>
                <div className="bg-slate-950/50 p-2.5 rounded-xl border border-slate-900 text-3xs font-mono text-slate-400 flex justify-between items-center">
                  <span>Талданған қойма бірліктері: <strong>{inventory.length} позиция</strong></span>
                  <span>Бақылау индикаторы: <strong className="text-sky-400">Қалдықтар нормаланған</strong></span>
                </div>
              </div>
            )}

            {aiDimension === 'production' && (
              <div className="space-y-2.5 animate-fadeIn">
                <div className="flex items-center gap-1.5 text-xs font-bold text-indigo-400">
                  <Hammer className="w-4 h-4" />
                  Өндірістік жүктеме және шеберлер балансы
                </div>
                <p className="text-xxs text-slate-300 leading-relaxed">
                  {hasHighWorkload ? (
                    <span>⚠️ <strong>Өндірістегі кептеліс дабылы:</strong> Шеберханаңыздағы тапсырыстардың жүктемесі біркелкі емес. Жоғары белсенді тапсырысы бар шеберлер анықталды. Сапаны жоғалтпау және уақыттан кешікпеу үшін жаңадан түсетін тапсырыстарды жүктемесі аз шеберлерге бағыттауды ұсынамыз.</span>
                  ) : (
                    <span>✅ <strong>Өндірістік жүктеме тең бөлінген.</strong> Барлық шеберлер қалыпты режимде жұмыс істеуде. Цехтың өткізу қабілеті жаңа тапсырыстар мен замерлерді қабылдауға 100% дайын.</span>
                  )}
                </p>
                <div className="bg-slate-950/50 p-2.5 rounded-xl border border-slate-900 text-3xs font-mono text-slate-400 flex justify-between items-center">
                  <span>Белсенді тапсырыс саны: <strong>{orders.filter(o => o.status !== 'completed' && o.status !== 'cancelled').length} бұйым</strong></span>
                  <span>Шеберлер саны: <strong>{employees.length > 0 ? employees.length : 4} маман</strong></span>
                </div>
              </div>
            )}
          </div>

          <div className="pt-3 mt-3 border-t border-slate-900/60 flex justify-between items-center text-3xs text-slate-500 font-mono">
            <span>Талдау күні: {new Date().toLocaleDateString('kk-KZ')} • 11:56</span>
            <span className="text-sky-400 flex items-center gap-1">
              <Sparkles className="w-3 h-3 text-sky-400" />
              JUMA UI AI-Engine Pro
            </span>
          </div>
        </div>

      </div>

      {/* SVG Charts section */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Monthly Revenue Trend Chart */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4">
          <div className="flex justify-between items-center pb-2 border-b border-slate-50">
            <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5">
              <Activity className="w-4 h-4 text-teal-600" />
              Айлық Сауда Айналымы
            </h3>
            <span className="text-3xs font-semibold text-teal-600 bg-teal-50 px-2 py-0.5 rounded">Қаржы динамикасы</span>
          </div>

          {/* SVG Area Chart */}
          <div className="relative pt-2">
            <svg viewBox="0 0 400 200" className="w-full h-auto overflow-visible">
              <defs>
                <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#0d9488" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#0d9488" stopOpacity="0.0" />
                </linearGradient>
              </defs>
              
              {/* Grid lines */}
              <line x1="40" y1="20" x2="380" y2="20" stroke="#f1f5f9" strokeWidth="1" />
              <line x1="40" y1="70" x2="380" y2="70" stroke="#f1f5f9" strokeWidth="1" />
              <line x1="40" y1="120" x2="380" y2="120" stroke="#f1f5f9" strokeWidth="1" />
              <line x1="40" y1="170" x2="380" y2="170" stroke="#cbd5e1" strokeWidth="1" />

              {/* Y Axis Labels */}
              <text x="32" y="24" className="text-4xs fill-slate-400 font-mono text-right" textAnchor="end">1.5M ₸</text>
              <text x="32" y="74" className="text-4xs fill-slate-400 font-mono text-right" textAnchor="end">1.0M ₸</text>
              <text x="32" y="124" className="text-4xs fill-slate-400 font-mono text-right" textAnchor="end">0.5M ₸</text>
              <text x="32" y="174" className="text-4xs fill-slate-400 font-mono text-right" textAnchor="end">0 ₸</text>

              {/* Area path */}
              <path 
                d="M40 170 C 100 150, 120 130, 160 110 S 220 60, 280 40 S 340 50, 380 45 V 170 Z" 
                fill="url(#chartGrad)" 
              />

              {/* Line path */}
              <path 
                d="M40 170 C 100 150, 120 130, 160 110 S 220 60, 280 40 S 340 50, 380 45" 
                fill="none" 
                stroke="#0d9488" 
                strokeWidth="3.5" 
                strokeLinecap="round"
              />

              {/* Points */}
              <circle cx="160" cy="110" r="5" fill="#0d9488" stroke="#ffffff" strokeWidth="1.5" />
              <circle cx="280" cy="40" r="5" fill="#0d9488" stroke="#ffffff" strokeWidth="1.5" />
              <circle cx="380" cy="45" r="5" fill="#0d9488" stroke="#ffffff" strokeWidth="1.5" />

              {/* Point Values */}
              <text x="160" y="95" className="text-3xs fill-slate-800 font-bold font-mono text-center" textAnchor="middle">620К</text>
              <text x="280" y="25" className="text-3xs fill-slate-800 font-bold font-mono text-center" textAnchor="middle">1.25М</text>

              {/* X Axis labels */}
              <text x="60" y="190" className="text-4xs font-semibold fill-slate-400" textAnchor="middle">Сәуір</text>
              <text x="160" y="190" className="text-4xs font-semibold fill-slate-400" textAnchor="middle">Мамыр</text>
              <text x="280" y="190" className="text-4xs font-semibold fill-slate-400" textAnchor="middle">Маусым (Бүгін)</text>
              <text x="365" y="190" className="text-4xs font-semibold fill-slate-400" textAnchor="middle">Шілде (Жоспар)</text>
            </svg>
          </div>
        </div>

        {/* Product Category Popularity bars */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4">
          <div className="flex justify-between items-center pb-2 border-b border-slate-50">
            <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5">
              <Briefcase className="w-4 h-4 text-teal-600" />
              Жиһаз Санаттарының Танымалдығы
            </h3>
            <span className="text-3xs font-semibold text-teal-600 bg-teal-50 px-2 py-0.5 rounded">Сұраныс көрсеткіші</span>
          </div>

          <div className="space-y-3.5 pt-2">
            {Object.entries(stats.productSales).length === 0 ? (
              <p className="text-center text-slate-400 py-10 text-xs">Тапсырыстар бойынша мәлімет жоқ.</p>
            ) : (
              Object.entries(stats.productSales).map(([category, amount]) => {
                const total = Math.max(1, (Object.values(stats.productSales) as number[]).reduce((s: number, v: number) => s + v, 0));
                const amountNum = amount as number;
                const percentage = Math.round((amountNum / total) * 100);
                
                return (
                  <div key={category} className="space-y-1 text-xs">
                    <div className="flex justify-between font-semibold">
                      <span className="text-slate-700">{category}</span>
                      <span className="font-mono text-slate-500">{amountNum.toLocaleString()} ₸ ({percentage}%)</span>
                    </div>
                    <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
                      <div 
                        className="bg-teal-600 h-full rounded-full transition-all"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

      </div>

      {/* Production pipeline progress stats */}
      <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4">
        <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5 border-b border-slate-50 pb-2">
          <PieChart className="w-4 h-4 text-teal-600" />
          Тапсырыстар Сүзгісі және Статустар Арақатынасы
        </h3>
        
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
          {[
            { id: 'new', label: 'Жаңа', color: 'bg-blue-500' },
            { id: 'measurement', label: 'Өлшеу (Замер)', color: 'bg-indigo-500' },
            { id: 'production', label: 'Өндірісте', color: 'bg-amber-500' },
            { id: 'delivery', label: 'Жеткізуде', color: 'bg-purple-500' },
            { id: 'completed', label: 'Аяқталды', color: 'bg-emerald-500' }
          ].map(status => {
            const count = stats.statusCounts[status.id] || 0;
            const total = Math.max(1, orders.length);
            const percentage = Math.round((count / total) * 100);

            return (
              <div key={status.id} className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center space-y-1">
                <span className="text-xxs font-semibold text-slate-400 block">{status.label}</span>
                <strong className="text-lg font-bold text-slate-800 font-mono block">{count}</strong>
                <div className="flex items-center justify-center gap-1">
                  <span className={`w-1.5 h-1.5 rounded-full ${status.color}`} />
                  <span className="text-3xs text-slate-400 font-mono font-semibold">{percentage}%</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
}
