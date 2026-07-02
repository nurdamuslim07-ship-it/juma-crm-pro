import React, { useState, useMemo } from 'react';
import { InventoryItem } from '../types';
import { Search, AlertTriangle, ArrowUpRight, ArrowDownRight, Archive, CheckCircle2, ShoppingBag, Calculator, Trash2, Plus, Percent, Hammer } from 'lucide-react';

interface InventoryModuleProps {
  inventory: InventoryItem[];
  onUpdateInventory: (item: InventoryItem) => void;
  onShowToast: (msg: string) => void;
}

interface PartItem {
  id: string;
  name: string;
  length: number; // in mm
  width: number;  // in mm
  count: number;
  edgeLong: number; // 0, 1, 2 sides to edgeband
  edgeShort: number; // 0, 1, 2 sides to edgeband
}

export default function InventoryModule({ inventory, onUpdateInventory, onShowToast }: InventoryModuleProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null);
  const [adjustQty, setAdjustQty] = useState('');
  const [adjustType, setAdjustType] = useState<'add' | 'deduct'>('add');
  const [adjustReason, setAdjustReason] = useState('Толықтыру');

  // Cutting Calculator State
  const [parts, setParts] = useState<PartItem[]>([
    { id: '1', name: 'Бүйір қабырға (Боковина)', length: 720, width: 560, count: 2, edgeLong: 2, edgeShort: 1 },
    { id: '2', name: 'Сөре (Внутренняя полка)', length: 568, width: 540, count: 3, edgeLong: 1, edgeShort: 0 },
    { id: '3', name: 'Түбі мен Төбесі (Дно/Крышка)', length: 600, width: 560, count: 2, edgeLong: 1, edgeShort: 2 },
  ]);
  const [newPartName, setNewPartName] = useState('');
  const [newPartLength, setNewPartLength] = useState('720');
  const [newPartWidth, setNewPartWidth] = useState('560');
  const [newPartCount, setNewPartCount] = useState('2');
  const [newPartEdgeLong, setNewPartEdgeLong] = useState<'0' | '1' | '2'>('1');
  const [newPartEdgeShort, setNewPartEdgeShort] = useState<'0' | '1' | '2'>('0');

  const filteredItems = inventory.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const lowStockItems = inventory.filter(item => item.quantity <= item.minQuantity);

  const handleAdjustStock = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedItem || !adjustQty) {
      onShowToast('Мөлшерді енгізіңіз');
      return;
    }

    const value = Number(adjustQty);
    if (isNaN(value) || value <= 0) {
      onShowToast('Дұрыс сан енгізіңіз');
      return;
    }

    let newQty = selectedItem.quantity;
    if (adjustType === 'add') {
      newQty += value;
    } else {
      if (value > selectedItem.quantity) {
        onShowToast('Қоймада мұндай мөлшерде мата/материал жоқ!');
        return;
      }
      newQty -= value;
    }

    onUpdateInventory({
      ...selectedItem,
      quantity: Number(newQty.toFixed(1))
    });

    onShowToast(`Қойма сәтті жаңартылды: ${selectedItem.name} ${adjustType === 'add' ? '+' : '-'}${value}`);
    setAdjustQty('');
    setSelectedItem(null);
  };

  return (
    <div className="space-y-6">
      
      {/* Title block */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Материалдар қоймасы</h2>
          <p className="text-xs text-slate-500">Жиһаз жасауға қажетті шикізат пен материалдардың қалдығы</p>
        </div>
        
        {lowStockItems.length > 0 && (
          <div className="bg-rose-50 border border-rose-100/80 rounded-xl px-3 py-2 flex items-center gap-2 text-rose-800 text-xs font-semibold">
            <AlertTriangle className="w-4 h-4 text-rose-500 animate-bounce" />
            <span>{lowStockItems.length} позиция таусылуға жақын!</span>
          </div>
        )}
      </div>

      {/* Grid of quick stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-teal-50 rounded-xl text-teal-600">
            <Archive className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Жалпы позициялар</span>
            <h3 className="text-lg font-bold text-slate-800">{inventory.length} түрлі материал</h3>
          </div>
        </div>

        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-50 rounded-xl text-amber-600">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Қалдық аз</span>
            <h3 className="text-lg font-bold text-slate-800">{lowStockItems.length} позиция</h3>
          </div>
        </div>

        <div className="bg-white border border-slate-100 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-indigo-50 rounded-xl text-indigo-600">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Қойманың жалпы құны</span>
            <h3 className="text-lg font-black text-indigo-600">
              {inventory.reduce((sum, item) => sum + (item.quantity * item.costPerUnit), 0).toLocaleString()} ₸
            </h3>
          </div>
        </div>
      </div>

      {/* Stock Adjustment Form (Modal styled overlay if item is selected) */}
      {selectedItem && (
        <form onSubmit={handleAdjustStock} className="bg-slate-900 text-white rounded-2xl p-5 border border-slate-800 shadow-xl space-y-4">
          <div className="flex justify-between items-center">
            <h3 className="font-bold text-sm text-teal-400">Қалдықты түзету: {selectedItem.name}</h3>
            <button type="button" onClick={() => setSelectedItem(null)} className="text-slate-400 hover:text-white text-xs font-semibold">
              Жабу
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 items-end">
            <div className="space-y-1.5 col-span-1">
              <label className="text-xxs uppercase font-semibold text-slate-400 block">Әрекет түрі</label>
              <div className="flex bg-slate-800 rounded-xl p-1 border border-slate-700">
                <button
                  type="button"
                  onClick={() => setAdjustType('add')}
                  className={`flex-1 text-center py-1.5 rounded-lg text-xs font-bold transition-all ${
                    adjustType === 'add' ? 'bg-teal-500 text-slate-950' : 'text-slate-300'
                  }`}
                >
                  Кіріс (+)
                </button>
                <button
                  type="button"
                  onClick={() => setAdjustType('deduct')}
                  className={`flex-1 text-center py-1.5 rounded-lg text-xs font-bold transition-all ${
                    adjustType === 'deduct' ? 'bg-rose-500 text-white' : 'text-slate-300'
                  }`}
                >
                  Шығыс (-)
                </button>
              </div>
            </div>

            <div className="space-y-1.5 col-span-1">
              <label className="text-xxs uppercase font-semibold text-slate-400 block">Мөлшері ({selectedItem.unit})</label>
              <input
                type="number"
                placeholder="Санын жазыңыз..."
                value={adjustQty}
                onChange={(e) => setAdjustQty(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-teal-500"
                required
              />
            </div>

            <div className="space-y-1.5 col-span-1">
              <label className="text-xxs uppercase font-semibold text-slate-400 block">Себебі</label>
              <input
                type="text"
                value={adjustReason}
                onChange={(e) => setAdjustReason(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-sm focus:outline-none"
              />
            </div>

            <button
              type="submit"
              className="bg-teal-500 hover:bg-teal-400 text-slate-950 font-bold text-xs py-2.5 px-4 rounded-xl transition cursor-pointer flex justify-center items-center gap-1"
            >
              Орындау
            </button>
          </div>
        </form>
      )}

      {/* Filters and Search */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
          <input 
            type="text" 
            placeholder="Материал атын іздеу..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
          />
        </div>

        <div className="flex gap-1 overflow-x-auto">
          {[
            { id: 'all', label: 'Барлығы' },
            { id: 'wood', label: 'Плиталар (ЛДСП/МДФ)' },
            { id: 'material', label: 'Столешницалар' },
            { id: 'hardware', label: 'Фурнитура' },
            { id: 'accessories', label: 'Жиектеме (Кромка)' },
          ].map((cat) => (
            <button
              key={cat.id}
              onClick={() => setCategoryFilter(cat.id)}
              className={`px-3 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition cursor-pointer ${
                categoryFilter === cat.id 
                  ? 'bg-teal-600 text-white shadow-sm' 
                  : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* Inventory Table/Grid */}
      <div className="bg-white border border-slate-100 rounded-2xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="bg-slate-50 text-slate-400 font-bold uppercase tracking-wider text-xxs border-b border-slate-100">
                <th className="py-3 px-4">Атауы</th>
                <th className="py-3 px-4">Санат</th>
                <th className="py-3 px-4 text-right">Қалдық</th>
                <th className="py-3 px-4 text-right">Өлшем бірлігі</th>
                <th className="py-3 px-4 text-right">Бағасы (бірлікке)</th>
                <th className="py-3 px-4 text-right">Жиынтық құны</th>
                <th className="py-3 px-4 text-center">Әрекеттер</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => {
                const isLow = item.quantity <= item.minQuantity;
                return (
                  <tr key={item.id} className="border-b border-slate-100 hover:bg-slate-50/50 transition">
                    <td className="py-3.5 px-4 font-semibold text-slate-800 flex items-center gap-2">
                      {isLow && (
                        <AlertTriangle className="w-3.5 h-3.5 text-rose-500" title="Қалдық деңгейі төмен!" />
                      )}
                      {item.name}
                    </td>
                    <td className="py-3.5 px-4 text-slate-500">
                      {item.category === 'wood' ? 'Плита (ЛДСП/МДФ)' :
                       item.category === 'material' ? 'Столешница / Тас' :
                       item.category === 'hardware' ? 'Фурнитура' :
                       item.category === 'accessories' ? 'Жиектеме (Кромка)' : 'Қосымша'}
                    </td>
                    <td className={`py-3.5 px-4 text-right font-bold font-mono ${isLow ? 'text-rose-600' : 'text-slate-800'}`}>
                      {item.quantity}
                    </td>
                    <td className="py-3.5 px-4 text-right text-slate-500">
                      {item.unit}
                    </td>
                    <td className="py-3.5 px-4 text-right font-mono text-slate-600">
                      {item.costPerUnit.toLocaleString()} ₸
                    </td>
                    <td className="py-3.5 px-4 text-right font-bold font-mono text-teal-600">
                      {(item.quantity * item.costPerUnit).toLocaleString()} ₸
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <button
                        onClick={() => {
                          setSelectedItem(item);
                          setAdjustType('add');
                          setAdjustReason('Толықтыру');
                        }}
                        className="px-2.5 py-1 bg-slate-50 hover:bg-teal-50 text-slate-600 hover:text-teal-700 border border-slate-200 rounded text-xxs font-bold transition cursor-pointer"
                      >
                        Басқару
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Cutting & Edgebanding Calculator Panel */}
      {(() => {
        // Memoized calculations inside render block or scope
        const calcResult = (() => {
          let totalAreaM2 = 0;
          let totalEdgeM = 0;

          parts.forEach(part => {
            const partAreaM2 = (part.length * part.width * part.count) / 1000000;
            totalAreaM2 += partAreaM2;

            const partEdgeM = ((part.length * part.edgeLong) + (part.width * part.edgeShort)) * part.count / 1000;
            totalEdgeM += partEdgeM;
          });

          const sheetArea = 5.8; // standard LDSP sheet is 2.8m x 2.07m = ~5.8m²
          const wasteFactor = 1.15; // 15% cutting kerfs & panel optimization waste
          const rawSheetsNeeded = (totalAreaM2 * wasteFactor) / sheetArea;
          const sheetsNeeded = Math.ceil(rawSheetsNeeded * 10) / 10;

          return {
            totalArea: Number(totalAreaM2.toFixed(2)),
            sheetsNeeded: parts.length > 0 ? (sheetsNeeded < 0.5 ? 0.5 : sheetsNeeded) : 0,
            edgeMetersNeeded: Math.round(totalEdgeM * 1.1), // 10% safety margin for edging application
          };
        })();

        const handleAddPart = (e: React.FormEvent) => {
          e.preventDefault();
          const l = Number(newPartLength);
          const w = Number(newPartWidth);
          const c = Number(newPartCount);

          if (isNaN(l) || l <= 0 || isNaN(w) || w <= 0 || isNaN(c) || c <= 0) {
            onShowToast('Өлшемдерді дұрыс енгізіңіз!');
            return;
          }

          const pName = newPartName.trim() || `Бөлшек #${parts.length + 1}`;

          const newPart: PartItem = {
            id: Date.now().toString(),
            name: pName,
            length: l,
            width: w,
            count: c,
            edgeLong: Number(newPartEdgeLong),
            edgeShort: Number(newPartEdgeShort),
          };

          setParts([...parts, newPart]);
          onShowToast(`"${pName}" пішу тізіміне қосылды`);
          setNewPartName('');
        };

        const handleRemovePart = (id: string) => {
          const itemToRemove = parts.find(p => p.id === id);
          setParts(parts.filter(p => p.id !== id));
          if (itemToRemove) {
            onShowToast(`"${itemToRemove.name}" тізімнен жойылды`);
          }
        };

        return (
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 text-slate-100 space-y-6 shadow-brand">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 pb-4 border-b border-slate-800">
              <div className="flex items-center gap-2.5">
                <div className="p-2 bg-teal-500/10 border border-teal-500/20 text-teal-400 rounded-xl">
                  <Calculator className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-base text-slate-100">Табақтарды пішу & Жиектеу калькуляторы</h3>
                  <p className="text-xxs text-slate-400">Шкафтар, ас үй гарнитуры бөлшектеріне қажетті ЛДСП плитасы мен Кромканы нақты есептеу</p>
                </div>
              </div>
              <span className="px-2.5 py-1 bg-teal-500/10 border border-teal-500/20 text-teal-400 rounded-xl text-xxs font-bold uppercase tracking-wider">
                Технолог құралы
              </span>
            </div>

            {/* Quick Metrics */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="bg-slate-850 border border-slate-800/80 p-4 rounded-2xl flex flex-col justify-between">
                <span className="text-xxs uppercase tracking-wider text-slate-400 font-bold">Бөлшектердің жалпы ауданы</span>
                <div className="flex items-baseline gap-1 mt-2">
                  <strong className="text-2xl font-black text-white">{calcResult.totalArea}</strong>
                  <span className="text-xs text-slate-400">м²</span>
                </div>
                <p className="text-[9px] text-slate-500 mt-1">Оңтайлы таза өлшемдердің қосындысы</p>
              </div>

              <div className="bg-slate-850 border border-teal-500/20 p-4 rounded-2xl flex flex-col justify-between relative overflow-hidden">
                <div className="absolute right-[-10px] top-[-10px] opacity-10">
                  <Percent className="w-16 h-16 text-teal-400" />
                </div>
                <span className="text-xxs uppercase tracking-wider text-teal-400 font-bold">Қажетті стандартты ЛДСП табағы</span>
                <div className="flex items-baseline gap-1 mt-2">
                  <strong className="text-2xl font-black text-teal-400">~{calcResult.sheetsNeeded}</strong>
                  <span className="text-xs text-teal-500">табақ</span>
                </div>
                <p className="text-[9px] text-slate-400 mt-1">Көлемі: 2800х2070мм, 15% пішу қалдығымен</p>
              </div>

              <div className="bg-slate-850 border border-slate-800/80 p-4 rounded-2xl flex flex-col justify-between">
                <span className="text-xxs uppercase tracking-wider text-slate-400 font-bold">Қажетті Кромка (Жиектеме)</span>
                <div className="flex items-baseline gap-1 mt-2">
                  <strong className="text-2xl font-black text-white">{calcResult.edgeMetersNeeded}</strong>
                  <span className="text-xs text-slate-400">метр</span>
                </div>
                <p className="text-[9px] text-slate-500 mt-1">Жиектелетін қабырғалар + 10% технологиялық қосымша</p>
              </div>
            </div>

            {/* Part input form */}
            <form onSubmit={handleAddPart} className="bg-slate-850/60 p-4 rounded-2xl border border-slate-800/60 space-y-3.5">
              <h4 className="font-bold text-xs text-slate-300 flex items-center gap-1.5">
                <Hammer className="w-3.5 h-3.5 text-teal-500" />
                Тізімге жаңа жиһаз бөлшегін енгізу
              </h4>
              <div className="grid grid-cols-1 md:grid-cols-6 gap-3">
                <div className="space-y-1 md:col-span-2">
                  <label className="text-[10px] font-bold text-slate-400">Бөлшек атауы (Қай жерікі)</label>
                  <input
                    type="text"
                    placeholder="Мысалы: Фасад MDF немесе Бүйір ЛДСП"
                    value={newPartName}
                    onChange={(e) => setNewPartName(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-teal-500"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400">Ұзындығы L, мм</label>
                  <input
                    type="number"
                    value={newPartLength}
                    onChange={(e) => setNewPartLength(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-xs text-center focus:outline-none"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400">Ені W, мм</label>
                  <input
                    type="number"
                    value={newPartWidth}
                    onChange={(e) => setNewPartWidth(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-xs text-center focus:outline-none"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400">Саны, дана</label>
                  <input
                    type="number"
                    value={newPartCount}
                    onChange={(e) => setNewPartCount(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3 py-2 text-xs text-center focus:outline-none"
                    required
                  />
                </div>

                <div className="flex items-end">
                  <button
                    type="submit"
                    className="w-full bg-teal-500 hover:bg-teal-400 text-slate-950 font-bold text-xs py-2 px-3 rounded-xl transition-all cursor-pointer flex justify-center items-center gap-1 active:scale-98"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Қосу
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 border-t border-slate-800/40">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 block">Ұзын қабырғаларын жиектеу (Кромкалау саны)</label>
                  <div className="flex gap-2">
                    {['0', '1', '2'].map(v => (
                      <button
                        key={v}
                        type="button"
                        onClick={() => setNewPartEdgeLong(v as any)}
                        className={`flex-1 py-1 px-3 border rounded-lg text-xxs font-bold transition ${
                          newPartEdgeLong === v 
                            ? 'bg-teal-500/10 border-teal-500/50 text-teal-400 font-bold' 
                            : 'bg-slate-800/50 border-slate-700 text-slate-400'
                        }`}
                      >
                        {v === '0' ? 'Жоқ' : v === '1' ? '1 жақ' : '2 жақ'}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 block">Қысқа қабырғаларын жиектеу (Кромкалау саны)</label>
                  <div className="flex gap-2">
                    {['0', '1', '2'].map(v => (
                      <button
                        key={v}
                        type="button"
                        onClick={() => setNewPartEdgeShort(v as any)}
                        className={`flex-1 py-1 px-3 border rounded-lg text-xxs font-bold transition ${
                          newPartEdgeShort === v 
                            ? 'bg-teal-500/10 border-teal-500/50 text-teal-400 font-bold' 
                            : 'bg-slate-800/50 border-slate-700 text-slate-400'
                        }`}
                      >
                        {v === '0' ? 'Жоқ' : v === '1' ? '1 жақ' : '2 жақ'}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </form>

            {/* Current parts list table */}
            <div className="space-y-4">
              <div className="space-y-2">
                <h4 className="font-bold text-xs text-slate-300">Пішу парағындағы ағымдағы бөлшектер тізімі</h4>
                <div className="overflow-x-auto border border-slate-800 rounded-2xl">
                  <table className="w-full text-left text-xxs border-collapse bg-slate-900/60">
                    <thead>
                      <tr className="bg-slate-850 text-slate-400 font-bold border-b border-slate-800 uppercase tracking-wider">
                        <th className="py-2.5 px-3">Атауы</th>
                        <th className="py-2.5 px-3 text-right">Өлшемі L x W (мм)</th>
                        <th className="py-2.5 px-3 text-right">Саны</th>
                        <th className="py-2.5 px-3 text-center">Ұзын Кромка</th>
                        <th className="py-2.5 px-3 text-center">Қысқа Кромка</th>
                        <th className="py-2.5 px-3 text-right">Аудан (м²)</th>
                        <th className="py-2.5 px-3 text-center">Әрекет</th>
                      </tr>
                    </thead>
                    <tbody>
                      {parts.map((p) => {
                        const area = ((p.length * p.width * p.count) / 1000000).toFixed(3);
                        return (
                          <tr key={p.id} className="border-b border-slate-800/60 hover:bg-slate-800/30 transition text-slate-300">
                            <td className="py-2 px-3 font-semibold text-slate-200">{p.name}</td>
                            <td className="py-2 px-3 text-right font-mono">{p.length} x {p.width}</td>
                            <td className="py-2 px-3 text-right font-bold text-teal-400 font-mono">{p.count} дана</td>
                            <td className="py-2 px-3 text-center font-mono">
                              {p.edgeLong === 0 ? <span className="text-slate-600">—</span> : `${p.edgeLong} жақ`}
                            </td>
                            <td className="py-2 px-3 text-center font-mono">
                              {p.edgeShort === 0 ? <span className="text-slate-600">—</span> : `${p.edgeShort} жақ`}
                            </td>
                            <td className="py-2 px-3 text-right font-mono">{area} м²</td>
                            <td className="py-2 px-3 text-center">
                              <button
                                onClick={() => handleRemovePart(p.id)}
                                className="p-1 hover:bg-rose-500/10 hover:text-rose-400 border border-transparent hover:border-rose-500/20 rounded transition text-slate-500 cursor-pointer"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                      {parts.length === 0 && (
                        <tr>
                          <td colSpan={7} className="py-6 text-center text-slate-500 italic">
                            Бөлшектер тізімі бос. Есептеу үшін бөлшектерді қосыңыз.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* 2D Cutting Map Visualizer */}
              {parts.length > 0 && (() => {
                const sheetW = 2800;
                const sheetH = 2070;
                const items: { id: string; name: string; w: number; h: number; originalId: string }[] = [];
                
                parts.forEach(p => {
                  for (let i = 0; i < p.count; i++) {
                    items.push({
                      id: `${p.id}-${i}`,
                      originalId: p.id,
                      name: p.name,
                      w: p.length,
                      h: p.width
                    });
                  }
                });

                // Sort by height descending to optimize shelf layout
                items.sort((a, b) => b.h - a.h);

                interface PackedPart {
                  id: string;
                  originalId: string;
                  name: string;
                  w: number;
                  h: number;
                  x: number;
                  y: number;
                }

                interface PackedSheet {
                  sheetIndex: number;
                  parts: PackedPart[];
                  usedAreaM2: number;
                  efficiency: number;
                }

                const sheets: PackedSheet[] = [];
                let currentParts: PackedPart[] = [];
                let currentX = 0;
                let currentY = 0;
                let currentShelfH = 0;

                const saveSheet = () => {
                  if (currentParts.length === 0) return;
                  const usedArea = currentParts.reduce((sum, p) => sum + (p.w * p.h), 0) / 1000000;
                  const sheetArea = (sheetW * sheetH) / 1000000;
                  const efficiency = Math.round((usedArea / sheetArea) * 100);
                  sheets.push({
                    sheetIndex: sheets.length + 1,
                    parts: currentParts,
                    usedAreaM2: Number(usedArea.toFixed(2)),
                    efficiency
                  });
                  currentParts = [];
                  currentX = 0;
                  currentY = 0;
                  currentShelfH = 0;
                };

                items.forEach(item => {
                  const itemW = Math.min(item.w, sheetW);
                  const itemH = Math.min(item.h, sheetH);

                  if (currentX + itemW <= sheetW && currentY + itemH <= sheetH) {
                    currentParts.push({
                      id: item.id,
                      originalId: item.originalId,
                      name: item.name,
                      w: itemW,
                      h: itemH,
                      x: currentX,
                      y: currentY
                    });
                    currentX += itemW;
                    currentShelfH = Math.max(currentShelfH, itemH);
                  } else {
                    currentY += currentShelfH;
                    currentX = 0;
                    currentShelfH = 0;

                    if (currentY + itemH <= sheetH) {
                      currentParts.push({
                        id: item.id,
                        originalId: item.originalId,
                        name: item.name,
                        w: itemW,
                        h: itemH,
                        x: currentX,
                        y: currentY
                      });
                      currentX += itemW;
                      currentShelfH = itemH;
                    } else {
                      saveSheet();
                      currentParts.push({
                        id: item.id,
                        originalId: item.originalId,
                        name: item.name,
                        w: itemW,
                        h: itemH,
                        x: currentX,
                        y: currentY
                      });
                      currentX += itemW;
                      currentShelfH = itemH;
                    }
                  }
                });

                saveSheet();

                return (
                  <div className="space-y-4 pt-6 border-t border-slate-800/60">
                    <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-2">
                      <div>
                        <h4 className="font-bold text-xs text-slate-300 flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse" />
                          📊 Интерактивті 2D пішу картасы (Орналасу схемасы)
                        </h4>
                        <p className="text-[10px] text-slate-500">Бөлшектердің стандартты ЛДСП плитасына (2800х2070мм) оңтайлы орналасу схемасы</p>
                      </div>
                      <span className="text-[10px] font-bold text-teal-400 font-mono bg-teal-500/10 border border-teal-500/20 px-2 py-0.5 rounded-lg w-max">
                        {sheets.length} плита жұмсалады
                      </span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      {sheets.map((sheet) => (
                        <div key={sheet.sheetIndex} className="bg-slate-950 rounded-2xl p-4 border border-slate-850 space-y-3 shadow-inner">
                          <div className="flex justify-between items-center text-[10px] font-mono text-slate-400">
                            <span className="font-bold text-teal-400 uppercase tracking-widest">Плита #{sheet.sheetIndex} (2.8 x 2.07 м)</span>
                            <div className="flex gap-2">
                              <span>Пайдалы аудан: <strong className="text-white">{sheet.usedAreaM2} м²</strong></span>
                              <span className="text-emerald-400 font-bold">Пайдалылық: {sheet.efficiency}%</span>
                            </div>
                          </div>

                          {/* Interactive responsive aspect-ratio container */}
                          <div className="w-full relative bg-slate-900/60 border border-slate-800 rounded-xl overflow-hidden aspect-[1.35/1] shadow-2xl">
                            {/* Grid back lines */}
                            <div className="absolute inset-0 bg-[linear-gradient(to_right,#1e293b_1px,transparent_1px),linear-gradient(to_bottom,#1e293b_1px,transparent_1px)] bg-[size:10%_10%] opacity-15" />
                            
                            {sheet.parts.map((p, idx) => {
                              const orig = parts.find(o => o.id === p.originalId);
                              const borderTop = orig && orig.edgeLong > 0 ? '2px solid #fbbf24' : '1px solid rgba(255,255,255,0.12)';
                              const borderBottom = orig && orig.edgeLong > 1 ? '2px solid #fbbf24' : '1px solid rgba(255,255,255,0.12)';
                              const borderLeft = orig && orig.edgeShort > 0 ? '2px solid #fbbf24' : '1px solid rgba(255,255,255,0.12)';
                              const borderRight = orig && orig.edgeShort > 1 ? '2px solid #fbbf24' : '1px solid rgba(255,255,255,0.12)';

                              return (
                                <div
                                  key={p.id}
                                  className="absolute flex flex-col items-center justify-center text-center p-1 overflow-hidden transition hover:brightness-125 select-none"
                                  style={{
                                    left: `${(p.x / sheetW) * 100}%`,
                                    top: `${(p.y / sheetH) * 100}%`,
                                    width: `${(p.w / sheetW) * 100}%`,
                                    height: `${(p.h / sheetH) * 100}%`,
                                    backgroundColor: idx % 3 === 0 ? 'rgba(13, 148, 136, 0.22)' : idx % 3 === 1 ? 'rgba(79, 70, 229, 0.22)' : 'rgba(219, 39, 119, 0.22)',
                                    borderTop,
                                    borderBottom,
                                    borderLeft,
                                    borderRight,
                                  }}
                                  title={`${p.name} (${p.w}x${p.h} мм)`}
                                >
                                  <span className="text-[7px] sm:text-[9px] font-extrabold text-white leading-none truncate max-w-full">
                                    {p.name}
                                  </span>
                                  <span className="text-[6px] sm:text-[8px] font-bold text-teal-400 font-mono mt-0.5 whitespace-nowrap">
                                    {p.w}x{p.h} мм
                                  </span>
                                </div>
                              );
                            })}
                          </div>

                          <div className="flex flex-wrap gap-x-4 gap-y-1 text-[9px] text-slate-500 font-medium">
                            <span className="flex items-center gap-1.5">
                              <span className="w-2.5 h-1.5 bg-teal-500/20 border border-teal-500/50 rounded-xs" />
                              Жиһаз бөлшегі
                            </span>
                            <span className="flex items-center gap-1.5">
                              <span className="w-2.5 h-0.5 bg-yellow-500 rounded-xs" />
                              Желімделетін Кромка (Жиек)
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })()}
            </div>
          </div>
        );
      })()}

    </div>
  );
}
