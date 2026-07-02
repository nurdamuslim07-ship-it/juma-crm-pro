import React, { useState, useMemo } from 'react';
import { DollarSign, Ruler, Settings, Palette, PlusCircle, Layout, Hammer, Sparkles, HelpCircle } from 'lucide-react';
import { Order } from '../types';

interface Visualizer3DProps {
  onAddOrderFromConfig: (orderData: Partial<Order>) => void;
  onShowToast: (msg: string) => void;
}

const MATERIAL_OPTIONS = [
  { id: 'mdf_gloss', name: 'МДФ Боялған Жалтыр (Glossy)', hex: '#faf9f6', borderHex: '#e2e8f0', costPerSqM: 32000, desc: 'Эксклюзивті жалтыр эмаль жабыны' },
  { id: 'mdf_matte', name: 'МДФ Боялған Күңгірт (Matte)', hex: '#4b5563', borderHex: '#374151', costPerSqM: 28000, desc: 'Саусақ ізі қалмайтын премиум күңгірт' },
  { id: 'acrylic', name: 'Жылтыр Акрил (High Gloss)', hex: '#0f172a', borderHex: '#1e293b', costPerSqM: 35000, desc: 'Терең түсті супер жылтыр акрил' },
  { id: 'egger_ldsp', name: 'ЛДСП Egger Премиум', hex: '#b45309', borderHex: '#78350f', costPerSqM: 18000, desc: 'Австриялық табиғи ағаш текстуралы ЛДСП' },
];

const HARDWARE_OPTIONS = [
  { id: 'blum', name: 'Blum Premium (Австрия)', cost: 120000, desc: 'Әлемдік №1 фурнитура, өмірлік кепілдік' },
  { id: 'hettich', name: 'Hettich Pro (Германия)', cost: 85000, desc: 'Неміс сенімділігі, біркелкі баяу сырғу' },
  { id: 'boyard', name: 'Boyard Standard (Ресей)', cost: 35000, desc: 'Оңтайлы баға мен лайықты сапа' },
  { id: 'dtc', name: 'DTC Eco (Қытай)', cost: 20000, desc: 'Бюджеттік автоматты топсалар жиынтығы' },
];

const COUNTERTOP_OPTIONS = [
  { id: 'quartz', name: 'Кварц Агломераты (Quartz)', costPerM: 80000, hex: '#f1f5f9', desc: 'Табиғи кварц үгіндісі, сызат түспейді' },
  { id: 'acrylic_stone', name: 'Жасанды Акрил Тас', costPerM: 55000, hex: '#e2e8f0', desc: 'Жігі жоқ, гигиеналық соққыға төзімді тас' },
  { id: 'hpl_plastic', name: 'HPL Компакт-пластика', costPerM: 30000, hex: '#78350f', desc: 'Ыстыққа төзімді, ағаш не тас имитациясы' },
  { id: 'none', name: 'Столешницасыз', costPerM: 0, hex: 'transparent', desc: 'Тек қаңқасы мен фасадтары' },
];

const HANDLE_OPTIONS = [
  { id: 'gola', name: 'Gola Интеграцияланған (Тұтқасыз)', costPerUnit: 0, desc: 'Заманауи тұтқасыз дизайн (профиль)' },
  { id: 'matte_black', name: 'Лофт Қара Күңгірт Тұтқа', costPerUnit: 2500, desc: 'Қара ұзын профильді металл' },
  { id: 'lux_gold', name: 'Алтын Түсті Luxury Тұтқа', costPerUnit: 4000, desc: 'Сәнді хромдалған алтын декор' },
];

export default function Visualizer3D({ onAddOrderFromConfig, onShowToast }: Visualizer3DProps) {
  const [cabinetType, setCabinetType] = useState<'kitchen' | 'wardrobe' | 'tv_cabinet'>('kitchen');
  const [selectedMaterial, setSelectedMaterial] = useState(MATERIAL_OPTIONS[0]);
  const [selectedHardware, setSelectedHardware] = useState(HARDWARE_OPTIONS[0]);
  const [selectedCountertop, setSelectedCountertop] = useState(COUNTERTOP_OPTIONS[0]);
  const [selectedHandle, setSelectedHandle] = useState(HANDLE_OPTIONS[0]);

  // Dimensions in cm
  const [cabWidth, setCabWidth] = useState(300); // 150-500cm
  const [cabHeight, setCabHeight] = useState(240); // 180-280cm
  const [cabDepth, setCabDepth] = useState(60); // 40-80cm

  const [doorCount, setDoorCount] = useState(4);
  const [drawerCount, setDrawerCount] = useState(3);
  const [clientName, setClientName] = useState('');
  const [clientPhone, setClientPhone] = useState('');

  // Dynamically calculate Door/Section count based on Width
  React.useEffect(() => {
    const recommendedDoors = Math.max(2, Math.round(cabWidth / 60));
    setDoorCount(recommendedDoors);
  }, [cabWidth]);

  // Cost and price calculation for carcass/cabinetry
  const calculations = useMemo(() => {
    const widthInMeters = cabWidth / 100;
    const heightInMeters = cabHeight / 100;
    const depthInMeters = cabDepth / 100;

    // 1. Carcass material (Laminated Chipboard for internal partitions/backplanes)
    // Formula: Total area estimation in sq. meters * Chipboard cost
    const carcassArea = (widthInMeters * heightInMeters * 2) + (widthInMeters * depthInMeters * 3) + (heightInMeters * depthInMeters * (doorCount + 1));
    const carcassCost = carcassArea * 7500; // Base 7,500 KZT per sq. meter for inside carcass boards

    // 2. Facade Front Area * Facade Material Cost
    const facadeArea = widthInMeters * heightInMeters;
    // Lower facades for TV console, full facades for wardrobe, split lower/upper for kitchen
    const facadeAdjustment = cabinetType === 'tv_cabinet' ? 0.4 : cabinetType === 'kitchen' ? 0.75 : 1.0;
    const finalFacadeArea = facadeArea * facadeAdjustment;
    const facadeCost = finalFacadeArea * selectedMaterial.costPerSqM;

    // 3. Countertop cost (only relevant for kitchens, calculated per running meter)
    const countertopCost = cabinetType === 'kitchen' ? widthInMeters * selectedCountertop.costPerM : 0;

    // 4. Hardware/Fittings cost
    // Base cost depending on Selected Brand + extra based on drawers/hinges count
    const baseHardwareCost = selectedHardware.cost;
    const additionalHardwareCost = (doorCount * 2 * 2000) + (drawerCount * 7000); // Hinges + drawer guides
    const totalHardwareCost = baseHardwareCost + additionalHardwareCost;

    // 5. Handles cost
    const handlesCost = selectedHandle.id !== 'gola' ? (doorCount + drawerCount) * selectedHandle.costPerUnit : 0;

    // 6. Craftsman installation & assembly labor cost (scales with size and door complexity)
    const baseLaborCost = 65000;
    const laborCost = baseLaborCost + (doorCount * 10000) + (drawerCount * 8000) + Math.round(cabWidth * 150);

    // Summing everything up to Prime Cost
    const primeCost = carcassCost + facadeCost + countertopCost + totalHardwareCost + handlesCost + laborCost;

    // Selling price: standard Cabinetry markup is 1.7x, rounded to nearest 10,000 KZT
    const baseSellingPrice = primeCost * 1.75;
    const roundedSellingPrice = Math.round(baseSellingPrice / 10000) * 10000;
    
    const profit = roundedSellingPrice - primeCost;
    const margin = Math.round((profit / roundedSellingPrice) * 100);

    return {
      carcassArea: Number(carcassArea.toFixed(1)),
      carcassCost: Math.round(carcassCost),
      facadeArea: Number(finalFacadeArea.toFixed(1)),
      facadeCost: Math.round(facadeCost),
      countertopCost: Math.round(countertopCost),
      hardwareCost: Math.round(totalHardwareCost),
      handlesCost: Math.round(handlesCost),
      laborCost: Math.round(laborCost),
      totalCost: Math.round(primeCost),
      sellingPrice: roundedSellingPrice,
      profit: Math.round(profit),
      margin,
    };
  }, [cabinetType, selectedMaterial, selectedHardware, selectedCountertop, selectedHandle, cabWidth, cabHeight, cabDepth, doorCount, drawerCount]);

  const handleCreateOrder = (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientName.trim()) {
      onShowToast('Клиент есімін енгізіңіз');
      return;
    }
    if (!clientPhone.trim()) {
      onShowToast('Телефон нөмірін енгізіңіз');
      return;
    }

    const typeKaz = cabinetType === 'kitchen' ? 'Ас үй гарнитуры' : cabinetType === 'wardrobe' ? 'Шкаф-купе' : 'ТВ консоль/Комод';

    const orderData: Partial<Order> = {
      clientName: clientName.trim(),
      clientPhone: clientPhone.trim(),
      productType: `${typeKaz} "${selectedMaterial.name.split(' ')[0]}" (${cabWidth}х${cabHeight}см)`,
      material: `Фасад: ${selectedMaterial.name}, Фурнитура: ${selectedHardware.name}${cabinetType === 'kitchen' && selectedCountertop.id !== 'none' ? `, Столешница: ${selectedCountertop.name}` : ''}, Тұтқа: ${selectedHandle.name}`,
      dimensions: `${cabWidth}х${cabDepth}х${cabHeight} см`,
      price: calculations.sellingPrice,
      paidAmount: Math.round(calculations.sellingPrice * 0.5), // 50% prepayment default
      notes: `3D Құрастырушыдан тапсырыс. Секция/Есік саны: ${doorCount}, Тартпалар: ${drawerCount}. Жабдықтар мен жинақтаушылар толық есептелген.`,
    };

    onAddOrderFromConfig(orderData);
    setClientName('');
    setClientPhone('');
    onShowToast('Корпустық жиһаз тапсырысы сәтті тіркелді!');
  };

  return (
    <div className="space-y-6" id="cabinetVisualizer">
      
      {/* Interactive Type Selector Tab */}
      <div className="flex bg-slate-100 dark:bg-slate-800 p-1.5 rounded-2xl gap-2 w-full max-w-lg shadow-inner">
        {[
          { id: 'kitchen', label: 'Ас үй гарнитуры', icon: Layout },
          { id: 'wardrobe', label: 'Шкаф-купе', icon: Settings },
          { id: 'tv_cabinet', label: 'ТВ Комод/Консоль', icon: Palette }
        ].map(type => (
          <button
            key={type.id}
            onClick={() => {
              setCabinetType(type.id as any);
              if (type.id === 'tv_cabinet') {
                setCabHeight(75);
                setCabDepth(45);
              } else if (type.id === 'kitchen') {
                setCabHeight(240);
                setCabDepth(60);
              } else {
                setCabHeight(250);
                setCabDepth(65);
              }
            }}
            className={`flex-1 py-2.5 rounded-xl text-xs font-black transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
              cabinetType === type.id 
                ? 'bg-teal-600 text-white shadow-md' 
                : 'text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700/50'
            }`}
          >
            <type.icon className="w-3.5 h-3.5" />
            {type.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Interactive Cabinet Mockup Stage */}
        <div className="lg:col-span-7 flex flex-col justify-between bg-slate-900/50 backdrop-blur-md border border-slate-700/50 rounded-3xl p-6 min-h-[420px] text-white relative overflow-hidden shadow-2xl">
          
          {/* Top Info badges */}
          <div className="absolute top-4 left-4 z-10">
            <span className="px-3 py-1 bg-teal-500/20 text-teal-300 text-xxs font-black uppercase tracking-wider rounded-full border border-teal-500/30 backdrop-blur-xs">
              3D Векторлық Сызба
            </span>
          </div>

          <div className="absolute top-4 right-4 z-10 flex gap-2">
            <span className="text-3xs text-slate-400 bg-slate-950/80 px-2 py-1 rounded border border-slate-800 font-mono">
              Ені: {cabWidth} см
            </span>
            <span className="text-3xs text-slate-400 bg-slate-950/80 px-2 py-1 rounded border border-slate-800 font-mono">
              Биіктігі: {cabHeight} см
            </span>
            <span className="text-3xs text-slate-400 bg-slate-950/80 px-2 py-1 rounded border border-slate-800 font-mono">
              Тереңдігі: {cabDepth} см
            </span>
          </div>

          {/* Interactive CSS Cabinet Builder rendering based on type */}
          <div className="flex-1 flex items-center justify-center py-10 relative">
            
            {/* Soft Ambient Floor Shadow */}
            <div 
              className="absolute bottom-6 h-4 bg-black/70 blur-xl rounded-full transition-all duration-300"
              style={{ width: `${Math.min(90, 45 + cabWidth / 6)}%` }}
            />

            {/* 3D Simulated Cabinet Wrapper */}
            <div 
              className="relative transition-all duration-300 ease-out flex flex-col items-center justify-center select-none"
              style={{ 
                width: `${Math.min(90, 40 + cabWidth / 5)}%`,
                height: cabinetType === 'tv_cabinet' ? '120px' : '280px',
                transform: 'perspective(800px) rotateX(10deg) rotateY(-8deg)',
              }}
            >
              
              {/* --- KITCHEN CABINET SET RENDERING --- */}
              {cabinetType === 'kitchen' && (
                <div className="w-full h-full flex flex-col justify-between relative">
                  
                  {/* 1. UPPER CABINETS (Верхний ряд шкафов) */}
                  <div className="w-full h-[32%] flex gap-1 z-10">
                    {Array.from({ length: doorCount }).map((_, i) => (
                      <div 
                        key={i} 
                        className="flex-1 h-full rounded-md border transition-colors duration-300 relative shadow-sm"
                        style={{ 
                          backgroundColor: selectedMaterial.hex,
                          borderColor: selectedMaterial.borderHex || 'rgba(0,0,0,0.25)',
                          boxShadow: 'inset 0 2px 4px rgba(255,255,255,0.1), inset -2px 0 3px rgba(0,0,0,0.1)'
                        }}
                      >
                        {/* Invisible/minimal profile or tiny handle at bottom edge */}
                        {selectedHandle.id !== 'gola' && (
                          <div 
                            className="absolute bottom-2 right-1.5 w-1 h-4 rounded-xs"
                            style={{ 
                              backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#000000',
                              border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                            }}
                          />
                        )}
                        {/* Door split lines */}
                        <div className="absolute right-0 top-0 bottom-0 w-px bg-black/15" />
                      </div>
                    ))}
                  </div>

                  {/* 2. GAP / Backsplash (Фартук) */}
                  <div className="w-full h-[22%] bg-slate-950/30 border-y border-slate-800/40 my-1 flex items-center justify-around px-4 relative">
                    <div className="text-[10px] text-slate-500 font-mono italic">Аралық фартук бөлiгі</div>
                    {/* Tiny outlines representing kitchen sink / tap or LED strip */}
                    <div className="absolute top-1 left-2 w-16 h-1 bg-cyan-400/30 blur-xs rounded animate-pulse" />
                    <div className="w-10 h-6 border border-slate-700/50 rounded flex items-center justify-center text-4xs text-slate-600">Шәйнек</div>
                    <div className="w-12 h-6 border border-slate-700/50 rounded flex items-center justify-center text-4xs text-slate-600">Ыдыс</div>
                  </div>

                  {/* 3. COUNTERTOP (Столешница) */}
                  <div 
                    className="w-[102%] -ml-[1%] h-4 rounded-sm z-20 shadow-md border-b transition-colors duration-300"
                    style={{ 
                      backgroundColor: selectedCountertop.hex === 'transparent' ? '#b45309' : selectedCountertop.hex,
                      borderColor: 'rgba(0,0,0,0.3)',
                      boxShadow: '0 4px 6px -1px rgba(0,0,0,0.3)'
                    }}
                  />

                  {/* 4. LOWER CABINETS (Нижний ряд шкафов с тартпалармен) */}
                  <div className="w-full h-[40%] flex gap-1 z-10 mt-1">
                    {Array.from({ length: doorCount }).map((_, i) => {
                      const isDrawerSection = i === 1 || i === Math.min(doorCount - 1, 2);
                      return (
                        <div 
                          key={i} 
                          className="flex-1 h-full rounded-md border transition-colors duration-300 relative shadow-md flex flex-col justify-between"
                          style={{ 
                            backgroundColor: selectedMaterial.hex,
                            borderColor: selectedMaterial.borderHex || 'rgba(0,0,0,0.25)',
                            filter: 'brightness(93%)'
                          }}
                        >
                          {isDrawerSection ? (
                            // Drawer blocks
                            <div className="w-full h-full flex flex-col gap-1 p-0.5">
                              {Array.from({ length: drawerCount }).map((_, dIdx) => (
                                <div 
                                  key={dIdx} 
                                  className="flex-1 border border-black/10 rounded-sm relative flex items-center justify-center"
                                  style={{ backgroundColor: 'rgba(255,255,255,0.02)' }}
                                >
                                  {/* Handle */}
                                  {selectedHandle.id !== 'gola' && (
                                    <div 
                                      className="w-8 h-1 rounded-full absolute"
                                      style={{ 
                                        backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#1e293b',
                                        border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                                      }}
                                    />
                                  )}
                                  <div className="absolute bottom-0.5 left-0 right-0 h-px bg-black/10" />
                                </div>
                              ))}
                            </div>
                          ) : (
                            // Standard doors with vertical alignment
                            <div className="w-full h-full relative">
                              {/* Handle */}
                              {selectedHandle.id !== 'gola' && (
                                <div 
                                  className="absolute top-2 left-2 w-1.5 h-6 rounded-xs"
                                  style={{ 
                                    backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#1e293b',
                                    border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                                  }}
                                />
                              )}
                              {/* Door partition */}
                              <div className="absolute right-0 top-0 bottom-0 w-px bg-black/15" />
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>

                </div>
              )}

              {/* --- SLIDING WARDROBE RENDERING --- */}
              {cabinetType === 'wardrobe' && (
                <div 
                  className="w-full h-full rounded-2xl border-4 p-1.5 transition-colors duration-300 relative shadow-2xl flex"
                  style={{ 
                    backgroundColor: selectedMaterial.hex,
                    borderColor: '#1e293b',
                    backgroundImage: 'linear-gradient(to right, rgba(0,0,0,0.3) 0%, rgba(255,255,255,0.02) 20%, rgba(0,0,0,0.1) 80%, rgba(0,0,0,0.4) 100%)'
                  }}
                >
                  {/* Sliding rail outlines */}
                  <div className="absolute top-1 left-2 right-2 h-1 bg-slate-800 border border-slate-700/50 rounded-full" />
                  <div className="absolute bottom-1 left-2 right-2 h-1.5 bg-slate-800 border border-slate-700/50 rounded-full" />

                  {/* Wardrobe door sections */}
                  {Array.from({ length: Math.max(2, Math.min(4, doorCount)) }).map((_, i) => {
                    const isMirror = i === 1; // Second door is usually a Mirror door
                    return (
                      <div 
                        key={i} 
                        className={`flex-1 h-full rounded-lg border-2 m-0.5 relative overflow-hidden transition-all duration-300 ${
                          isMirror ? 'bg-gradient-to-tr from-sky-300/30 via-slate-100/50 to-sky-200/40 backdrop-blur-xxs' : ''
                        }`}
                        style={{ 
                          backgroundColor: isMirror ? 'rgba(255,255,255,0.15)' : selectedMaterial.hex,
                          borderColor: 'rgba(0,0,0,0.3)',
                          boxShadow: 'inset 0 0 10px rgba(0,0,0,0.4)'
                        }}
                      >
                        {isMirror && (
                          <div className="absolute inset-0 flex flex-col justify-between p-3 opacity-90 select-none pointer-events-none">
                            <div className="w-full h-[85%] border border-white/20 rounded flex items-center justify-center">
                              <span className="text-[9px] font-bold text-slate-300/60 font-mono uppercase tracking-widest">АЙНА / MIRROR</span>
                            </div>
                            <div className="w-1.5 h-16 bg-slate-400/50 rounded-full mx-auto" />
                          </div>
                        )}

                        {!isMirror && (
                          <div className="w-full h-full relative flex flex-col justify-between p-2">
                            {/* Wooden Panel horizontal geometric lines */}
                            <div className="w-full h-px bg-black/25 my-8" />
                            <div className="w-full h-px bg-black/25 my-8" />
                            
                            {/* Handle strip */}
                            <div 
                              className="absolute top-1/3 bottom-1/3 left-1.5 w-1 h-20 rounded-full"
                              style={{ 
                                backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#1e293b',
                                border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                              }}
                            />
                            
                            <div className="w-full h-px bg-black/25 my-8" />
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}

              {/* --- TV CABINET / CONSOLE RENDERING --- */}
              {cabinetType === 'tv_cabinet' && (
                <div className="w-full h-full flex flex-col justify-end relative">
                  
                  {/* Flat screen outline representation just behind console */}
                  <div className="absolute top-[-110px] left-1/2 -translate-x-1/2 w-[70%] h-24 bg-slate-950/80 rounded border border-slate-800 flex flex-col justify-center items-center">
                    <div className="w-2.5 h-2.5 rounded-full bg-red-500/30 animate-pulse mb-1" />
                    <span className="text-[7px] text-slate-600 font-mono">ТЕЛЕВИЗОР ПАНЕЛІ (Сызық)</span>
                  </div>

                  {/* TV Console Main Cabinet */}
                  <div 
                    className="w-full h-16 rounded-xl border-2 transition-colors duration-300 relative shadow-xl flex gap-1 p-1"
                    style={{ 
                      backgroundColor: selectedMaterial.hex,
                      borderColor: selectedMaterial.borderHex || 'rgba(0,0,0,0.25)',
                      boxShadow: 'inset 0 4px 6px rgba(255,255,255,0.1)'
                    }}
                  >
                    {Array.from({ length: Math.max(3, doorCount) }).map((_, i) => {
                      const isMiddleDrawer = i === 1 || i === 2;
                      return (
                        <div 
                          key={i} 
                          className="flex-1 h-full rounded border border-black/15 relative flex items-center justify-center shadow-inner"
                          style={{ backgroundColor: 'rgba(0,0,0,0.15)' }}
                        >
                          {isMiddleDrawer ? (
                            <div className="w-full h-full flex flex-col justify-center items-center relative">
                              <div className="w-full h-1/2 border-b border-black/10" />
                              
                              {/* Handle */}
                              {selectedHandle.id !== 'gola' && (
                                <div 
                                  className="w-6 h-1 rounded-full absolute top-1/4"
                                  style={{ 
                                    backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#000000',
                                    border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                                  }}
                                />
                              )}
                              {selectedHandle.id !== 'gola' && (
                                <div 
                                  className="w-6 h-1 rounded-full absolute bottom-1/4"
                                  style={{ 
                                    backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#000000',
                                    border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                                  }}
                                />
                              )}
                            </div>
                          ) : (
                            <div className="w-full h-full relative">
                              {/* Standard swing door */}
                              {selectedHandle.id !== 'gola' && (
                                <div 
                                  className="absolute top-1/2 -translate-y-1/2 left-2 w-1.5 h-4 rounded-xs"
                                  style={{ 
                                    backgroundColor: selectedHandle.id === 'lux_gold' ? '#fbbf24' : '#000000',
                                    border: selectedHandle.id === 'lux_gold' ? '1px solid #d97706' : 'none'
                                  }}
                                />
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

            </div>
          </div>

          {/* Specifications Footer Info */}
          <div className="bg-slate-850/80 border border-slate-800/80 rounded-2xl p-3.5 flex flex-wrap gap-4 items-center justify-between text-3xs text-slate-300 font-mono">
            <span className="flex items-center gap-1.5">
              <Ruler className="w-3.5 h-3.5 text-teal-400" />
              Көлемі: {cabWidth}х{cabDepth}х{cabHeight} см (Ені/Тереңдігі/Биіктігі)
            </span>
            <span className="flex items-center gap-1.5">
              <Palette className="w-3.5 h-3.5 text-teal-400" />
              Текстура: {calculations.facadeArea} м² Фасадтық аудан
            </span>
          </div>

        </div>

        {/* Configurations Panel */}
        <div className="lg:col-span-5 flex flex-col justify-between space-y-6">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-6 border border-slate-100 dark:border-slate-800 shadow-sm space-y-5 transition-colors">
            
            <h3 className="text-sm font-black text-slate-900 dark:text-slate-100 flex items-center gap-2 uppercase tracking-wider">
              <Settings className="w-4 h-4 text-teal-500" />
              Жиһаз параметрлері
            </h3>

            {/* Width Slider */}
            <div className="space-y-1.5">
              <div className="flex justify-between text-xs font-semibold">
                <span className="text-slate-700 dark:text-slate-300">Ені (Ұзындығы)</span>
                <span className="font-mono text-teal-600 dark:text-teal-400 font-bold">{cabWidth} см</span>
              </div>
              <input 
                type="range" 
                min="150" 
                max="500" 
                value={cabWidth} 
                onChange={(e) => setCabWidth(Number(e.target.value))}
                className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-lg appearance-none cursor-pointer accent-teal-600"
              />
              <div className="flex justify-between text-[8px] text-slate-400 font-mono uppercase">
                <span>1.5м (Кіші комод)</span>
                <span>3.0м (Орташа)</span>
                <span>5.0м (Үлкен гарнитур)</span>
              </div>
            </div>

            {/* Height & Depth Grid sliders */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <div className="flex justify-between text-xs font-semibold">
                  <span className="text-slate-700 dark:text-slate-300">Биіктігі</span>
                  <span className="font-mono text-teal-500 font-bold">{cabHeight} см</span>
                </div>
                <input 
                  type="range" 
                  min={cabinetType === 'tv_cabinet' ? '40' : '180'} 
                  max={cabinetType === 'tv_cabinet' ? '120' : '285'} 
                  value={cabHeight} 
                  onChange={(e) => setCabHeight(Number(e.target.value))}
                  className="w-full h-1 bg-slate-100 dark:bg-slate-800 rounded-lg appearance-none cursor-pointer accent-teal-500"
                />
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between text-xs font-semibold">
                  <span className="text-slate-700 dark:text-slate-300">Тереңдігі</span>
                  <span className="font-mono text-teal-500 font-bold">{cabDepth} см</span>
                </div>
                <input 
                  type="range" 
                  min="40" 
                  max="80" 
                  value={cabDepth} 
                  onChange={(e) => setCabDepth(Number(e.target.value))}
                  className="w-full h-1 bg-slate-100 dark:bg-slate-800 rounded-lg appearance-none cursor-pointer accent-teal-500"
                />
              </div>
            </div>

            {/* Material Selector */}
            <div className="space-y-2">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400 block uppercase tracking-wider">Фасад Материалы</span>
              <div className="grid grid-cols-2 gap-2 text-xs">
                {MATERIAL_OPTIONS.map((material) => (
                  <button
                    key={material.id}
                    onClick={() => setSelectedMaterial(material)}
                    className={`p-2.5 rounded-xl border text-left flex flex-col justify-between gap-1 cursor-pointer transition ${
                      selectedMaterial.id === material.id 
                        ? 'border-teal-500 bg-teal-500/10 text-teal-900 dark:text-teal-300' 
                        : 'border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-slate-800 dark:text-slate-400'
                    }`}
                  >
                    <div className="flex items-center gap-1.5">
                      <div className="w-3 h-3 rounded-full border border-black/10" style={{ backgroundColor: material.hex }} />
                      <span className="font-bold text-[10px] truncate">{material.name.split(' ')[0]}</span>
                    </div>
                    <span className="text-[8px] opacity-75 font-mono">{material.costPerSqM.toLocaleString()} ₸/м²</span>
                  </button>
                ))}
              </div>
              <p className="text-[10px] text-slate-400 italic font-medium">{selectedMaterial.desc}</p>
            </div>

            {/* Dynamic parts selector (Tabletop & Fittings) */}
            <div className="grid grid-cols-2 gap-4">
              
              {/* Fittings Selection */}
              <div className="space-y-1.5">
                <label className="text-3xs font-black uppercase tracking-wider text-slate-400 block">Фурнитура бренді</label>
                <select
                  value={selectedHardware.id}
                  onChange={(e) => {
                    const matched = HARDWARE_OPTIONS.find(h => h.id === e.target.value);
                    if (matched) setSelectedHardware(matched);
                  }}
                  className="w-full bg-slate-50 dark:bg-slate-850 border border-slate-200 dark:border-slate-800 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-teal-500 text-slate-850 dark:text-slate-100 font-bold cursor-pointer"
                >
                  {HARDWARE_OPTIONS.map(hw => (
                    <option key={hw.id} value={hw.id}>{hw.name.split(' ')[0]}</option>
                  ))}
                </select>
              </div>

              {/* Countertop selection - Only for kitchens */}
              {cabinetType === 'kitchen' ? (
                <div className="space-y-1.5">
                  <label className="text-3xs font-black uppercase tracking-wider text-slate-400 block">Столешница түрі</label>
                  <select
                    value={selectedCountertop.id}
                    onChange={(e) => {
                      const matched = COUNTERTOP_OPTIONS.find(c => c.id === e.target.value);
                      if (matched) setSelectedCountertop(matched);
                    }}
                    className="w-full bg-slate-50 dark:bg-slate-850 border border-slate-200 dark:border-slate-800 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-teal-500 text-slate-850 dark:text-slate-100 font-bold cursor-pointer"
                  >
                    {COUNTERTOP_OPTIONS.map(ct => (
                      <option key={ct.id} value={ct.id}>{ct.name.split(' ')[0]}</option>
                    ))}
                  </select>
                </div>
              ) : (
                <div className="space-y-1.5">
                  <label className="text-3xs font-black uppercase tracking-wider text-slate-400 block">Тартпалар саны</label>
                  <div className="flex items-center bg-slate-50 dark:bg-slate-850 border border-slate-200 dark:border-slate-800 rounded-xl p-1 h-[38px]">
                    {[2, 3, 4].map(num => (
                      <button
                        key={num}
                        onClick={() => setDrawerCount(num)}
                        className={`flex-1 text-center py-1 rounded-lg text-xs font-black transition-all ${
                          drawerCount === num 
                            ? 'bg-teal-600 text-white shadow-sm' 
                            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
                        }`}
                      >
                        {num}
                      </button>
                    ))}
                  </div>
                </div>
              )}

            </div>

            {/* Handle Options selection */}
            <div className="space-y-1.5">
              <label className="text-3xs font-black uppercase tracking-wider text-slate-400 block">Есік тұтқаларының дизайны</label>
              <select
                value={selectedHandle.id}
                onChange={(e) => {
                  const matched = HANDLE_OPTIONS.find(h => h.id === e.target.value);
                  if (matched) setSelectedHandle(matched);
                }}
                className="w-full bg-slate-50 dark:bg-slate-850 border border-slate-200 dark:border-slate-800 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-teal-500 text-slate-850 dark:text-slate-100 font-bold cursor-pointer"
              >
                {HANDLE_OPTIONS.map(handle => (
                  <option key={handle.id} value={handle.id}>{handle.name}</option>
                ))}
              </select>
            </div>

          </div>

          {/* Pricing Breakdown Panel */}
          <div className="bg-slate-50 dark:bg-slate-900 rounded-3xl p-6 border border-slate-100 dark:border-slate-800 shadow-sm space-y-4 transition-colors">
            <h4 className="text-xs font-black text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Hammer className="w-4 h-4 text-slate-400" />
              Шығындар мен баға белгілеу талдауы
            </h4>

            <div className="grid grid-cols-2 gap-y-2 text-xs text-slate-600 dark:text-slate-400 font-medium">
              <span>Қаңқа қабырғалары (ЛДСП, {calculations.carcassArea}м²):</span>
              <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.carcassCost.toLocaleString()} ₸</span>
              
              <span>Таңдалған фасад ({calculations.facadeArea}м²):</span>
              <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.facadeCost.toLocaleString()} ₸</span>
              
              {cabinetType === 'kitchen' && (
                <>
                  <span>Үстел беті (Столешница):</span>
                  <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.countertopCost.toLocaleString()} ₸</span>
                </>
              )}

              <span>Автоматты фурнитура & петли:</span>
              <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.hardwareCost.toLocaleString()} ₸</span>
              
              <span>Есік тұтқалары:</span>
              <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.handlesCost.toLocaleString()} ₸</span>
              
              <span>Мамандардың еңбекақысы:</span>
              <span className="text-right font-semibold font-mono text-slate-800 dark:text-slate-200">{calculations.laborCost.toLocaleString()} ₸</span>

              <div className="col-span-2 border-t border-slate-200 dark:border-slate-800 my-1"></div>

              <span className="font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider text-xxs">Қосынды Өзіндік Құны:</span>
              <span className="text-right font-bold font-mono text-slate-900 dark:text-slate-100">{calculations.totalCost.toLocaleString()} ₸</span>

              <span className="font-bold text-teal-600 dark:text-teal-400 uppercase tracking-wider text-xxs">Таза Пайда (+{calculations.margin}%):</span>
              <span className="text-right font-bold font-mono text-emerald-500">+{calculations.profit.toLocaleString()} ₸</span>
            </div>

            <div className="bg-teal-600/10 dark:bg-teal-500/10 border border-teal-500/20 dark:border-teal-500/30 rounded-2xl p-4 flex justify-between items-center text-teal-900 dark:text-teal-300">
              <div>
                <span className="text-[10px] uppercase tracking-widest font-black opacity-80 block">Сату Нарықтық Бағасы</span>
                <h3 className="text-xl font-black font-mono text-teal-600 dark:text-teal-400 mt-0.5">{calculations.sellingPrice.toLocaleString()} ₸</h3>
              </div>
              <div className="text-right">
                <span className="text-[10px] uppercase tracking-widest font-black opacity-80 block">Компания Маржасы</span>
                <h3 className="text-lg font-black font-mono text-emerald-600 dark:text-emerald-400 mt-0.5">{calculations.margin}%</h3>
              </div>
            </div>
          </div>

        </div>

      </div>

      {/* CRM Order Registry Form */}
      <div className="bg-slate-900 text-white rounded-3xl p-6 border border-slate-800 shadow-xl space-y-4">
        <div>
          <h3 className="text-base font-black text-teal-400 flex items-center gap-2 uppercase tracking-wider">
            <PlusCircle className="w-5 h-5 text-teal-400 animate-pulse" />
            Сызбаны CRM-ге тапсырыс ретінде тіркеу
          </h3>
          <p className="text-xs text-slate-400 mt-1">Осы корпустық жиһаз есептеуін клиент атына жазып, базаға сақтап қойыңыз (50% алдын ала төлеммен):</p>
        </div>

        <form onSubmit={handleCreateOrder} className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
          <div className="space-y-1.5">
            <label className="text-xxs text-slate-400 font-bold uppercase tracking-widest">Клиенттің Аты-жөні</label>
            <input 
              type="text" 
              placeholder="Мәселен: Айдар Қайратов" 
              value={clientName}
              onChange={(e) => setClientName(e.target.value)}
              className="w-full bg-slate-850 border border-slate-800 rounded-2xl px-4 py-3.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-teal-500"
              required
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xxs text-slate-400 font-bold uppercase tracking-widest">Байланыс телефоны</label>
            <input 
              type="tel" 
              placeholder="+7 777 555 4433" 
              value={clientPhone}
              onChange={(e) => setClientPhone(e.target.value)}
              className="w-full bg-slate-850 border border-slate-800 rounded-2xl px-4 py-3.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-teal-500"
              required
            />
          </div>

          <button
            type="submit"
            className="w-full bg-teal-500 hover:bg-teal-400 text-slate-950 font-black text-xs uppercase tracking-wider px-6 py-4 rounded-2xl transition-all flex items-center justify-center gap-2 cursor-pointer shadow-lg active:scale-98"
          >
            <PlusCircle className="w-4 h-4" />
            Базаға Сақтау
          </button>
        </form>
      </div>

    </div>
  );
}
