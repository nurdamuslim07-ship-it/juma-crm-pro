import React, { useState, useEffect } from 'react';
import { Order, OrderStatus, ProductionStage, Employee } from '../types';
import { Search, Plus, Printer, CheckCircle, Clock, Trash2, Edit2, AlertCircle, Sparkles, MessageSquare, Smartphone, Coins, Percent, FileText } from 'lucide-react';

const getCleanPhoneForWhatsApp = (phone: string): string => {
  const digits = phone.replace(/\D/g, '');
  if (digits.startsWith('8')) {
    return '7' + digits.substring(1);
  }
  if (digits.length === 10) {
    return '7' + digits;
  }
  return digits;
};

const getWhatsAppTemplateText = (order: Order, type: string): string => {
  const remaining = order.price - order.paidAmount;
  const deliveryDateFormatted = order.deliveryDate ? new Date(order.deliveryDate).toLocaleDateString('kk-KZ') : 'жақын арада';
  const stageNames: Record<string, string> = {
    frame: 'қаңқасын дайындау (распил)',
    foam: 'фасадтарын өңдеу (фрезеровка)',
    upholstery: 'бөлшектерді жиектеу (кромкалау)',
    assembly: 'фурнитура орнату және соңғы құрастыру',
    ready: 'дайын өнімді тексеру'
  };
  const currentStageName = stageNames[order.productionStage || 'frame'] || 'дайындау';

  switch (type) {
    case 'accepted':
      return `Құрметті ${order.clientName}!\n\nJUMA UI MEBEL шеберханасынан хабарласып тұрмыз. Сіздің "${order.productType}" жиһазы бойынша INV-${order.id} тапсырысыңыз сәтті қабылданды!\n\n💰 Бағасы: ${order.price.toLocaleString()} ₸\n💳 Алдын ала төлем: ${order.paidAmount.toLocaleString()} ₸\n⏳ Төленетін қалдық: ${remaining.toLocaleString()} ₸\n🚚 Жоспарлы дайын болу күні: ${deliveryDateFormatted}\n\nСенім білдіргеніңізге үлкен рақмет! Сапалы әрі әдемі етіп дайындауға уәде береміз. 🛋️✨`;
    
    case 'measurement':
      return `Қайырлы күн, ${order.clientName}!\n\n📐 JUMA UI MEBEL шеберханасынан хабарласып тұрмыз. Сіздің тапсырысыңыз бойынша өлшем алу (замер) жұмыстары жоспарланды.\n\nӨлшеуші маман сізге қосымша хабарласып, мекенжайыңыз бен келу уақытын нақтылайды. Мекенжайда өзіңіздің немесе жауапты адамның болуын сұраймыз.\n\nРақмет, күніңіз сәтті өтсін!`;

    case 'production':
      return `Құрметті ${order.clientName}!\n\n🔨 Жағымды жаңалық! Сіздің "${order.productType}" жиһазыңыз бойынша тапсырыс цехымызға өндіріске берілді.\n\nҚазіргі дайындық кезеңі: ${currentStageName}.\nБіздің тәжірибелі шеберлер бұйымыңызды барлық технологиялық стандарттарға сай мұқият жасауда.\n\nСұрақтарыңыз болса, кез келген уақытта жауап беруге дайынбыз. JUMA UI MEBEL.`;

    case 'ready':
      return `Құрметті ${order.clientName}!\n\n🚚 Сіздің "${order.productType}" жиһазыңыз цехымызда 100% дайын болды!\n\nБүгін-ертең жеткізу және орнату бригадасын шығаруды жоспарлап отырмыз. Үйде болатын ыңғайлы уақытты нақтылау үшін бізге жауап беруіңізді сұраймыз.\n\n💳 Жеткізу алдындағы төленетін қалдық: ${remaining.toLocaleString()} ₸.\nКездескенше! JUMA UI MEBEL.`;

    case 'completed':
      return `Құрметті ${order.clientName}!\n\n✨ Құттықтаймыз! Тапсырысыңызды жеткізіп, сәтті орнаттық. JUMA UI MEBEL-ді таңдағаныңызға үлкен рақмет!\n\nЖаңа жиһазыңыз отбасыңызға ұзақ жылдар бойы қуаныш, жылулық пен жайлылық сыйласын. Қызмет сапасына баға беріп, пікір қалдырсаңыз өте қуанышты боламыз.\n\nҮйіңіз құтты болсын! 💖🛋️`;

    default:
      return '';
  }
};

interface OrdersModuleProps {
  orders: Order[];
  employees: Employee[];
  onAddOrder: (order: Order) => void;
  onUpdateOrder: (order: Order) => void;
  onDeleteOrder: (id: string) => void;
  onShowToast: (msg: string) => void;
  showAddFormProp?: boolean;
  onShowAddFormChange?: (show: boolean) => void;
}

const STATUS_KAZAKH: Record<OrderStatus, string> = {
  new: 'Жаңа',
  measurement: 'Өлшеу (Замер)',
  production: 'Өндірісте',
  delivery: 'Жеткізуде',
  completed: 'Аяқталды',
  cancelled: 'Күші жойылды'
};

const STAGE_KAZAKH: Record<ProductionStage, string> = {
  frame: 'Қабырғаларды пішу (Распил)',
  foam: 'Фасад өңдеу (Фрезеровка)',
  upholstery: 'Жиектеу (Кромкалау)',
  assembly: 'Фурнитура & Соңғы құрастыру',
  ready: 'Дайын өнім'
};

export default function OrdersModule({ 
  orders, 
  employees, 
  onAddOrder, 
  onUpdateOrder, 
  onDeleteOrder, 
  onShowToast,
  showAddFormProp,
  onShowAddFormChange
}: OrdersModuleProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showAddForm, setShowAddForm] = useState(false);

  useEffect(() => {
    if (showAddFormProp !== undefined) {
      setShowAddForm(showAddFormProp);
    }
  }, [showAddFormProp]);

  const handleSetShowAddForm = (val: boolean) => {
    setShowAddForm(val);
    if (onShowAddFormChange) {
      onShowAddFormChange(val);
    }
  };
  
  // Form State
  const [clientName, setClientName] = useState('');
  const [clientPhone, setClientPhone] = useState('');
  const [productType, setProductType] = useState('Ас үй гарнитуры (Кухня)');
  const [material, setMaterial] = useState('');
  const [dimensions, setDimensions] = useState('');
  const [price, setPrice] = useState('');
  const [paidAmount, setPaidAmount] = useState('');
  const [notes, setNotes] = useState('');
  const [employeeId, setEmployeeId] = useState('');
  const [status, setStatus] = useState<OrderStatus>('new');

  // Printing state
  const [invoiceOrder, setInvoiceOrder] = useState<Order | null>(null);

  // WhatsApp states
  const [whatsappOrder, setWhatsappOrder] = useState<Order | null>(null);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('accepted');
  const [whatsappMessageText, setWhatsappMessageText] = useState<string>('');

  // Cost Estimator states
  const [calculatingOrder, setCalculatingOrder] = useState<Order | null>(null);
  const [woodSheetsCount, setWoodSheetsCount] = useState('3');
  const [woodSheetPrice, setWoodSheetPrice] = useState('28000');
  const [edgeMeters, setEdgeMeters] = useState('40');
  const [edgePrice, setEdgePrice] = useState('400');
  const [fittingsCost, setFittingsCost] = useState('45000');
  const [laborCostState, setLaborCostState] = useState('50000');
  const [overheadCost, setOverheadCost] = useState('15000');

  // Contract (Dogovor) states
  const [contractOrder, setContractOrder] = useState<Order | null>(null);
  const [clientIin, setClientIin] = useState('');
  const [contractWarrantyMonths, setContractWarrantyMonths] = useState('12');
  const [contractTermsDays, setContractTermsDays] = useState('15');
  const [contractSeller, setContractSeller] = useState('«JUMA UI MEBEL» ЖК-сы');
  const [contractActiveTab, setContractActiveTab] = useState<string>('new');

  useEffect(() => {
    if (whatsappOrder) {
      setWhatsappMessageText(getWhatsAppTemplateText(whatsappOrder, selectedTemplate));
    }
  }, [whatsappOrder, selectedTemplate]);

  const filteredOrders = orders.filter(order => {
    const matchesSearch = order.clientName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          order.productType.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          order.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = statusFilter === 'all' || order.status === statusFilter;
    return matchesSearch && matchesFilter;
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientName || !clientPhone || !productType || !price) {
      onShowToast('Міндетті өрістерді толтырыңыз!');
      return;
    }

    const newOrder: Order = {
      id: `ORD-${Math.floor(100 + Math.random() * 900)}`,
      clientName: clientName.trim(),
      clientPhone: clientPhone.trim(),
      productType: productType.trim(),
      material: material.trim() || 'Енгізілмеген',
      dimensions: dimensions.trim() || 'Стандарт',
      price: Number(price),
      paidAmount: Number(paidAmount) || 0,
      status: status,
      productionStage: status === 'production' ? 'frame' : undefined,
      createdAt: new Date().toISOString(),
      deliveryDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 10 days default
      notes: notes.trim(),
      employeeId: employeeId || undefined
    };

    onAddOrder(newOrder);
    onShowToast('Тапсырыс сәтті қосылды!');
    handleSetShowAddForm(false);
    resetForm();
  };

  const resetForm = () => {
    setClientName('');
    setClientPhone('');
    setProductType('Ас үй гарнитуры (Кухня)');
    setMaterial('');
    setDimensions('');
    setPrice('');
    setPaidAmount('');
    setNotes('');
    setEmployeeId('');
    setStatus('new');
  };

  const updateStatus = (order: Order, newStatus: OrderStatus) => {
    const updated: Order = { ...order, status: newStatus };
    if (newStatus === 'production' && !order.productionStage) {
      updated.productionStage = 'frame';
    } else if (newStatus === 'completed') {
      updated.productionStage = 'ready';
      updated.paidAmount = order.price; // Paid in full upon completion
    }
    onUpdateOrder(updated);
    onShowToast(`Тапсырыс статусы "${STATUS_KAZAKH[newStatus]}" болып жаңартылды`);
  };

  const updateStage = (order: Order, stage: ProductionStage) => {
    onUpdateOrder({ ...order, productionStage: stage });
    onShowToast(`Өндіріс кезеңі "${STAGE_KAZAKH[stage]}" деп белгіленді`);
  };

  const handlePrint = (order: Order) => {
    setInvoiceOrder(order);
  };

  const handlePrintContract = (order: Order, iin: string, warranty: string, terms: string, seller: string) => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      onShowToast('Принтер терезесін ашуға рұқсат беріңіз!');
      return;
    }
    const remaining = order.price - order.paidAmount;
    const dateFormatted = new Date(order.createdAt).toLocaleDateString('kk-KZ');

    printWindow.document.write(`
      <html>
        <head>
          <title>Келісімшарт № ${order.id}</title>
          <style>
            body { font-family: 'Times New Roman', Times, serif; padding: 40px; color: #000; line-height: 1.5; font-size: 14px; }
            .header { text-align: center; font-weight: bold; margin-bottom: 30px; }
            .title { font-size: 16px; text-transform: uppercase; margin-bottom: 5px; }
            .subtitle { font-size: 12px; font-weight: normal; margin-bottom: 20px; }
            .meta { display: flex; justify-content: space-between; margin-bottom: 25px; font-weight: bold; }
            .section-title { font-weight: bold; margin-top: 20px; margin-bottom: 8px; text-transform: uppercase; font-size: 13px; border-bottom: 1px solid #000; padding-bottom: 2px; }
            .content { text-align: justify; margin-bottom: 15px; text-indent: 30px; }
            .table { width: 100%; border-collapse: collapse; margin: 15px 0; }
            .table th, .table td { border: 1px solid #000; padding: 8px; text-align: left; }
            .table th { background-color: #f2f2f2; }
            .signatures { display: flex; justify-content: space-between; margin-top: 50px; }
            .signature-block { width: 45%; }
            .sig-line { border-bottom: 1px solid #000; margin-top: 40px; height: 20px; }
            @media print {
              body { padding: 20px; }
              .no-print { display: none !important; }
            }
          </style>
        </head>
        <body>
          <div class="no-print" style="text-align: right; margin-bottom: 20px;">
            <button onclick="window.print()" style="padding: 10px 20px; background-color: #2563eb; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; font-family: sans-serif;">📄 Келісімшартты басып шығару (Печать)</button>
          </div>
          <div class="header">
            <div class="title">ЖИҺАЗ ДАЙЫНДАУ ЖӘНЕ САТЫП АЛУ-САТУ ШАРТЫ № ${order.id}</div>
            <div class="subtitle">Жеке тапсырыс бойынша жиһаз бұйымдарын өндіру келісімі</div>
          </div>
          <div class="meta">
            <div>Алматы қаласы</div>
            <div>Күні: ${dateFormatted} ж.</div>
          </div>
          
          <div class="section-title">1. Келісім Тараптары</div>
          <p class="content">Осы Келісімшарт бұдан әрі «Орындаушы» деп аталатын <b>${seller}</b> атынан бір тараптан және бұдан әрі «Тапсырыс беруші» деп аталатын азамат(ша) <b>${order.clientName}</b> (ЖСН: <b>${iin || '_________________'}</b>, тел: <b>${order.clientPhone}</b>) екінші тараптан, төмендегілер туралы осы Шартты жасасты:</p>
          
          <div class="section-title">2. Шарттың мәні және сипаттамасы</div>
          <p class="content">2.1. Орындаушы Тапсырыс берушінің тапсырысы бойынша және бекітілген өлшемдерге сәйкес келесі бұйымды дайындауға, жеткізуге және орнатуға міндеттенеді: <b>${order.productType}</b>.</p>
          <p class="content">2.2. Бұйымның сипаттамалары:</p>
          <table class="table">
            <tr><th>Бұйым атауы</th><td>${order.productType}</td></tr>
            <tr><th>Өлшемдері (Ені х Тереңдігі х Биіктігі)</th><td>${order.dimensions}</td></tr>
            <tr><th>Материалы мен Түсі</th><td>${order.material}</td></tr>
            <tr><th>Арнайы ескертпелер</th><td>${order.notes || 'Жоқ'}</td></tr>
          </table>

          <div class="section-title">3. Құны және төлеу тәртібі</div>
          <p class="content">3.1. Осы Шарт бойынша дайындалатын жиһаз бұйымының жалпы құны: <b>${order.price.toLocaleString()} ₸ (теңге)</b> құрайды.</p>
          <p class="content">3.2. Тапсырыс беруші Шартқа қол қойған сәтте жалпы соманың <b>${order.paidAmount.toLocaleString()} ₸ (теңге)</b> көлемінде алдын ала төлем (кепілдік аванс) енгізеді.</p>
          <p class="content">3.3. Тапсырыстың қалған сомасы <b>${remaining.toLocaleString()} ₸ (теңге)</b> бұйым толық дайын болып, жеткізіліп орнатылғаннан кейін Орындаушыға қолма-қол немесе аударым түрінде төленеді.</p>

          <div class="section-title">4. Орындау мерзімі және шарттары</div>
          <p class="content">4.1. Орындаушы тапсырысты Шарт жасалған және аванс төленген күннен бастап <b>${terms} жұмыс күні</b> ішінде сапалы етіп дайындап, жеткізуге міндеттенеді.</p>
          <p class="content">4.2. Егер Тапсырыс беруші тарапынан өлшем алу немесе дизайнды мақұлдау кешіктірілсе, дайындау мерзімі сәйкесінше ұзартылады.</p>

          <div class="section-title">5. Сапа кепілдігі және міндеттемелер</div>
          <p class="content">5.1. Орындаушы дайындалған жиһаз бұйымының сапасына <b>${warranty} ай</b> көлемінде кепілдік береді. Кепілдік бұйым дұрыс пайдаланылмаған жағдайда (ылғал тарту, соққы, механикалық зақымдар) өз күшін жояды.</p>
          <p class="content">5.2. Даулы мәселелер Қазақстан Республикасының қолданыстағы заңнамасына сәйікес Алматы қаласының сот органдарында қаралады.</p>

          <div class="signatures">
            <div class="signature-block">
              <b>Орындаушы:</b><br>
              ${seller}<br>
              Қол қолы: _________________<br>
              М.П. (мөр орны)
            </div>
            <div class="signature-block">
              <b>Тапсырыс беруші:</b><br>
              ${order.clientName}<br>
              ЖСН: ${iin || '_________________'}<br>
              Қол қолы: _________________
            </div>
          </div>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  return (
    <div className="space-y-6">
      
      {/* Header and Add Action */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Тапсырыстарды бақылау</h2>
          <p className="text-xs text-slate-500">Жиһаз тапсырыстары мен олардың жасалу барысы</p>
        </div>
        <button
          onClick={() => handleSetShowAddForm(!showAddForm)}
          className="bg-teal-600 hover:bg-teal-700 text-white font-medium text-sm px-4 py-2.5 rounded-xl transition-all flex items-center gap-1.5 cursor-pointer shadow-sm active:scale-98"
        >
          <Plus className="w-4 h-4" />
          Жаңа тапсырыс қосу
        </button>
      </div>

      {/* Add New Order Modal/Form */}
      {showAddForm && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4 overflow-y-auto animate-fadeIn">
          <div className="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-3xl border border-slate-100 dark:border-slate-800 shadow-2xl p-6 md:p-8 space-y-4 relative max-h-[90vh] overflow-y-auto">
            
            {/* Modal Header */}
            <div className="flex justify-between items-center border-b border-slate-100 dark:border-slate-800 pb-3">
              <h3 className="font-bold text-slate-800 dark:text-white flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-teal-600 animate-pulse" />
                Жаңа тапсырыс формасы
              </h3>
              <button 
                type="button" 
                onClick={() => handleSetShowAddForm(false)} 
                className="text-slate-400 hover:text-slate-600 dark:hover:text-white text-sm bg-slate-100 dark:bg-slate-800 w-8 h-8 rounded-full flex items-center justify-center transition cursor-pointer"
              >
                ✕
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Клиенттің Аты-жөні *</label>
                <input 
                  type="text" 
                  placeholder="Мәселен: Әсел Жұмаева" 
                  value={clientName}
                  onChange={(e) => setClientName(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Телефон нөмірі *</label>
                <input 
                  type="tel" 
                  placeholder="+7 707 555 6677" 
                  value={clientPhone}
                  onChange={(e) => setClientPhone(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Бұйым түрі (Тауар) *</label>
                <select
                  value={productType}
                  onChange={(e) => setProductType(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500 cursor-pointer"
                >
                  <option value="Ас үй гарнитуры (Кухня)" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Ас үй гарнитуры (Кухня)</option>
                  <option value="Шкаф-купе (Wardrobe)" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Шкаф-купе (Wardrobe)</option>
                  <option value="Киім бөлмесі (Гардероб)" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Киім бөлмесі (Гардероб)</option>
                  <option value="Кіреберіс жиһазы (Прихожая)" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Кіреберіс жиһазы (Прихожая)</option>
                  <option value="ТД тумбасы немесе Комод" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">ТД тумбасы немесе Комод</option>
                  <option value="Жеке Жоба (Тапсырыс)" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Жеке Жоба (Тапсырыс)</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Фасад түрі және Материалы</label>
                <input 
                  type="text" 
                  placeholder="Мысалы: Боялған МДФ Жалтыр + Blum петли" 
                  value={material}
                  onChange={(e) => setMaterial(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Өлшемдері (Ені х Тереңдігі х Биіктігі)</label>
                <input 
                  type="text" 
                  placeholder="Мысалы: 240х100х85 см" 
                  value={dimensions}
                  onChange={(e) => setDimensions(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Бағасы (₸) *</label>
                <input 
                  type="number" 
                  placeholder="380000" 
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                  required
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Төленгені (Алдын ала төлем) (₸)</label>
                <input 
                  type="number" 
                  placeholder="200000" 
                  value={paidAmount}
                  onChange={(e) => setPaidAmount(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400 font-medium">Жауапты шебер (Қызметкер)</label>
                <select
                  value={employeeId}
                  onChange={(e) => setEmployeeId(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none"
                >
                  <option value="" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Шеберді бекіту...</option>
                  {employees.map(emp => (
                    <option key={emp.id} value={emp.id} className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">{emp.name} ({emp.role === 'upholsterer' ? 'Қаптаушы' : emp.role === 'carpenter' ? 'Ағаш ұстасы' : emp.role})</option>
                  ))}
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Бастапқы статус</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as OrderStatus)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none"
                >
                  <option value="new" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Жаңа</option>
                  <option value="measurement" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Өлшеу (Замер)</option>
                  <option value="production" className="bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100">Өндірісте</option>
                </select>
              </div>

              <div className="col-span-1 md:col-span-2 space-y-1">
                <label className="text-xs font-semibold text-slate-500 dark:text-slate-400">Ерекше ескертпелер / Талаптар</label>
                <textarea 
                  rows={2}
                  placeholder="Клиенттің қосымша тілектері, фурнитура маркасы, есік пен тартпа саны және т.б." 
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-teal-500"
                />
              </div>

              <div className="col-span-1 md:col-span-2 flex justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800 mt-2">
                <button 
                  type="button" 
                  onClick={() => { handleSetShowAddForm(false); resetForm(); }}
                  className="px-4 py-2 text-xs font-medium text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
                >
                  Болдырмау
                </button>
                <button 
                  type="submit" 
                  className="bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs px-5 py-2.5 rounded-xl transition shadow-sm cursor-pointer"
                >
                  Тапсырысты Сақтау
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Search and Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
          <input 
            type="text" 
            placeholder="Клиент аты, бұйым түрі немесе код бойынша іздеу..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm placeholder-slate-400 text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
          />
        </div>

        <div className="flex gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          {['all', 'new', 'measurement', 'production', 'delivery', 'completed', 'cancelled'].map((tab) => (
            <button
              key={tab}
              onClick={() => setStatusFilter(tab)}
              className={`px-3 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition cursor-pointer ${
                statusFilter === tab 
                  ? 'bg-teal-600 text-white shadow-sm' 
                  : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
              }`}
            >
              {tab === 'all' ? 'Барлығы' : STATUS_KAZAKH[tab as OrderStatus]}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredOrders.length === 0 ? (
          <div className="col-span-1 md:col-span-2 bg-white rounded-2xl p-10 border border-slate-100 text-center text-slate-400">
            <AlertCircle className="w-8 h-8 text-slate-300 mx-auto mb-2" />
            <span>Іздеу нәтижесі бойынша тапсырыстар табылмады.</span>
          </div>
        ) : (
          filteredOrders.map((order) => {
            const assignedEmp = employees.find(e => e.id === order.employeeId);
            const remainingAmount = order.price - order.paidAmount;
            
            return (
              <div key={order.id} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm flex flex-col justify-between hover:border-slate-200 transition-all">
                <div className="space-y-3">
                  {/* Top bar with ID & Status */}
                  <div className="flex justify-between items-center">
                    <span className="text-xs font-black font-mono text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      {order.id}
                    </span>
                    <span className={`px-2.5 py-1 rounded-full text-xxs font-black uppercase tracking-wider ${
                      order.status === 'completed' ? 'bg-emerald-100 text-emerald-800' :
                      order.status === 'production' ? 'bg-amber-100 text-amber-800' :
                      order.status === 'delivery' ? 'bg-purple-100 text-purple-800' :
                      order.status === 'measurement' ? 'bg-indigo-100 text-indigo-800' :
                      order.status === 'new' ? 'bg-blue-100 text-blue-800' : 'bg-slate-100 text-slate-600'
                    }`}>
                      {STATUS_KAZAKH[order.status]}
                    </span>
                  </div>

                  {/* Client & Product details */}
                  <div>
                    <h3 className="font-bold text-slate-800 text-base">{order.clientName}</h3>
                    <p className="text-xs text-slate-500">{order.clientPhone}</p>
                    <div className="mt-2.5 space-y-1 text-xs">
                      <p className="text-slate-700 font-medium"><strong className="text-slate-400">Бұйым:</strong> {order.productType}</p>
                      <p className="text-slate-700"><strong className="text-slate-400">Материал:</strong> {order.material}</p>
                      <p className="text-slate-700"><strong className="text-slate-400">Өлшемі:</strong> {order.dimensions}</p>
                      {order.notes && (
                        <p className="bg-slate-50 text-slate-500 p-2 rounded-lg mt-1 italic text-xxs border border-slate-100">
                          "{order.notes}"
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Production stage sub-flow */}
                  {order.status === 'production' && (
                    <div className="bg-amber-50/50 border border-amber-100 rounded-xl p-3 space-y-2">
                      <div className="flex justify-between items-center text-xxs text-amber-800 font-bold uppercase tracking-wider">
                        <span>Өндіріс кезеңі</span>
                        <span className="font-mono text-amber-600 bg-white px-1.5 py-0.5 rounded shadow-xxs">
                          {STAGE_KAZAKH[order.productionStage || 'frame']}
                        </span>
                      </div>
                      <div className="flex gap-1">
                        {(['frame', 'foam', 'upholstery', 'assembly', 'ready'] as ProductionStage[]).map((stg) => {
                          const stages: ProductionStage[] = ['frame', 'foam', 'upholstery', 'assembly', 'ready'];
                          const currentIdx = stages.indexOf(order.productionStage || 'frame');
                          const thisIdx = stages.indexOf(stg);
                          const isDone = thisIdx <= currentIdx;
                          return (
                            <button
                              key={stg}
                              onClick={() => updateStage(order, stg)}
                              className={`flex-1 h-2.5 rounded-full transition-all cursor-pointer ${
                                isDone ? 'bg-amber-500' : 'bg-slate-200 hover:bg-slate-300'
                              }`}
                              title={STAGE_KAZAKH[stg]}
                            />
                          );
                        })}
                      </div>
                    </div>
                  )}

                  {/* Assigned craftsman */}
                  <div className="flex items-center justify-between text-xs text-slate-500 border-t border-slate-50 pt-3">
                    <span className="font-medium text-xxs">Жауапты шебер:</span>
                    {assignedEmp ? (
                      <span className="font-semibold text-slate-800 flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                        {assignedEmp.name}
                      </span>
                    ) : (
                      <select
                        onChange={(e) => onUpdateOrder({ ...order, employeeId: e.target.value })}
                        className="bg-slate-50 border border-slate-200 rounded p-1 text-xxs cursor-pointer"
                      >
                        <option value="">Тағайындау...</option>
                        {employees.map(e => (
                          <option key={e.id} value={e.id}>{e.name}</option>
                        ))}
                      </select>
                    )}
                  </div>

                  {/* Pricing Breakdown inside Card */}
                  <div className="bg-slate-50 p-2.5 rounded-xl flex justify-between items-center text-xs font-mono border border-slate-100">
                    <div>
                      <p className="text-xxs text-slate-400 font-semibold font-sans">ЖАЛПЫ БАҒАСЫ</p>
                      <p className="font-bold text-slate-800">{order.price.toLocaleString()} ₸</p>
                    </div>
                    <div>
                      <p className="text-xxs text-slate-400 font-semibold font-sans">ТӨЛЕНГЕНІ</p>
                      <p className="font-bold text-teal-600">{order.paidAmount.toLocaleString()} ₸</p>
                    </div>
                    <div>
                      <p className="text-xxs text-slate-400 font-semibold font-sans">ҚАЛДЫҒЫ</p>
                      <p className={`font-bold ${remainingAmount > 0 ? 'text-amber-600' : 'text-emerald-600'}`}>
                        {remainingAmount.toLocaleString()} ₸
                      </p>
                    </div>
                  </div>

                  {/* Order profitability analysis if saved */}
                  {order.costBreakdown && (() => {
                    const cb = order.costBreakdown;
                    const totalMaterials = (cb.woodSheetsCount * cb.woodSheetPrice) + (cb.edgeMeters * cb.edgePrice) + cb.fittingsCost;
                    const totalCost = totalMaterials + cb.laborCost + cb.overheadCost;
                    const netProfit = order.price - totalCost;
                    const profitMargin = order.price > 0 ? (netProfit / order.price) * 100 : 0;
                    const isHigh = profitMargin >= 35;
                    const isMedium = profitMargin >= 20 && profitMargin < 35;
                    return (
                      <div className={`p-2.5 rounded-xl border flex flex-col gap-1 ${
                        isHigh ? 'bg-emerald-500/5 border-emerald-500/10 text-emerald-800 dark:text-emerald-300' :
                        isMedium ? 'bg-amber-500/5 border-amber-500/10 text-amber-800 dark:text-amber-300' : 
                        'bg-rose-500/5 border-rose-500/10 text-rose-800 dark:text-rose-300'
                      }`}>
                        <div className="flex justify-between items-center text-[10px]">
                          <span className="font-semibold flex items-center gap-1 text-slate-500 dark:text-slate-400">
                            <Coins className="w-3 h-3 text-slate-400" />
                            Шеберхана шығыны:
                          </span>
                          <span className="font-bold font-mono">{totalCost.toLocaleString()} ₸</span>
                        </div>
                        <div className="flex justify-between items-center text-3xs font-black">
                          <span>Таза пайда (Маржа):</span>
                          <span className="font-mono">
                            {netProfit >= 0 ? '+' : ''}{netProfit.toLocaleString()} ₸ ({Math.round(profitMargin)}%)
                          </span>
                        </div>
                      </div>
                    );
                  })()}
                </div>

                {/* Bottom interactive controllers */}
                <div className="flex gap-2 border-t border-slate-50 pt-3 mt-4 justify-between items-center">
                  <div className="flex gap-1.5">
                    {order.status !== 'completed' && order.status !== 'cancelled' && (
                      <button
                        onClick={() => updateStatus(order, 'completed')}
                        className="bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xxs font-black px-2 py-1.5 rounded-lg flex items-center gap-1 transition cursor-pointer"
                        title="Тапсырысты аяқтау"
                      >
                        <CheckCircle className="w-3.5 h-3.5" />
                        Аяқтау
                      </button>
                    )}
                    {order.status !== 'production' && order.status !== 'completed' && order.status !== 'cancelled' && (
                      <button
                        onClick={() => updateStatus(order, 'production')}
                        className="bg-amber-50 hover:bg-amber-100 text-amber-700 text-xxs font-black px-2 py-1.5 rounded-lg flex items-center gap-1 transition cursor-pointer"
                      >
                        <Clock className="w-3.5 h-3.5" />
                        Өндіріске беру
                      </button>
                    )}
                  </div>

                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        setCalculatingOrder(order);
                        if (order.costBreakdown) {
                          setWoodSheetsCount(String(order.costBreakdown.woodSheetsCount));
                          setWoodSheetPrice(String(order.costBreakdown.woodSheetPrice));
                          setEdgeMeters(String(order.costBreakdown.edgeMeters));
                          setEdgePrice(String(order.costBreakdown.edgePrice));
                          setFittingsCost(String(order.costBreakdown.fittingsCost));
                          setLaborCostState(String(order.costBreakdown.laborCost));
                          setOverheadCost(String(order.costBreakdown.overheadCost));
                        } else {
                          // set intelligent default presets based on product dimensions or price
                          setWoodSheetsCount('3');
                          setWoodSheetPrice('28000');
                          setEdgeMeters('45');
                          setEdgePrice('400');
                          setFittingsCost(String(Math.round(order.price * 0.12)));
                          setLaborCostState(String(Math.round(order.price * 0.18)));
                          setOverheadCost(String(Math.round(order.price * 0.05)));
                        }
                      }}
                      className="p-2 text-indigo-500 hover:text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition cursor-pointer animate-pulse"
                      title="Өзіндік құн мен таза пайда калькуляторы"
                    >
                      <Coins className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => {
                        setContractOrder(order);
                        setClientIin(order.clientIin || '');
                        setContractWarrantyMonths(String(order.contractWarrantyMonths || '12'));
                        setContractTermsDays(String(order.contractTermsDays || '15'));
                        setContractSeller(order.contractSeller || '«JUMA UI MEBEL» ЖК-сы');
                      }}
                      className="p-2 text-blue-500 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg transition cursor-pointer"
                      title="Келісімшарт (Договор) жасау"
                    >
                      <FileText className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => {
                        setWhatsappOrder(order);
                        // pre-select template based on status
                        if (order.status === 'new') setSelectedTemplate('accepted');
                        else if (order.status === 'measurement') setSelectedTemplate('measurement');
                        else if (order.status === 'production') setSelectedTemplate('production');
                        else if (order.status === 'delivery') setSelectedTemplate('ready');
                        else if (order.status === 'completed') setSelectedTemplate('completed');
                      }}
                      className="p-2 text-emerald-500 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition cursor-pointer"
                      title="WhatsApp арқылы хабарлама жіберу"
                    >
                      <MessageSquare className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => handlePrint(order)}
                      className="p-2 text-slate-400 hover:text-slate-600 bg-slate-50 rounded-lg hover:bg-slate-100 transition cursor-pointer"
                      title="Түбіртек (Invoice) басып шығару"
                    >
                      <Printer className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm('Тапсырысты өшіргіңіз келе ме?')) {
                          onDeleteOrder(order.id);
                          onShowToast('Тапсырыс базадан жойылды');
                        }
                      }}
                      className="p-2 text-rose-400 hover:text-rose-600 bg-slate-50 hover:bg-rose-50 rounded-lg transition cursor-pointer"
                      title="Өшіру"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Printable Invoice modal */}
      {invoiceOrder && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-lg w-full border border-slate-100 shadow-2xl relative space-y-4">
            
            {/* Stamp / Logo decoration */}
            <div className="border-b-2 border-slate-950 pb-4 text-center space-y-1 relative">
              <span className="font-sans font-black text-slate-950 tracking-widest text-lg">JUMA UI MEBEL CRM</span>
              <p className="text-xxs uppercase tracking-wider font-semibold text-slate-500">Ресми төлем түбіртегі</p>
              <p className="text-xxs text-slate-400">Мекенжай: Алматы қ., Райымбек даңғылы, 245</p>
            </div>

            {/* Bill Details */}
            <div className="space-y-2.5 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-400 font-semibold uppercase tracking-wider text-xxs">Құжат нөмірі:</span>
                <span className="font-bold font-mono text-slate-800">INV-{invoiceOrder.id}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400 font-semibold uppercase tracking-wider text-xxs">Күні:</span>
                <span className="font-mono text-slate-800">{new Date(invoiceOrder.createdAt).toLocaleDateString('kk-KZ')}</span>
              </div>
              
              <div className="border-t border-dashed border-slate-200 my-2"></div>
              
              <div>
                <span className="text-slate-400 font-semibold uppercase tracking-wider text-xxs block mb-1">Клиент:</span>
                <p className="font-bold text-slate-800">{invoiceOrder.clientName}</p>
                <p className="text-slate-500">{invoiceOrder.clientPhone}</p>
              </div>

              <div>
                <span className="text-slate-400 font-semibold uppercase tracking-wider text-xxs block mb-1">Тауар (Жиһаз бұйымы):</span>
                <p className="font-bold text-slate-800">{invoiceOrder.productType}</p>
                <p className="text-slate-500">Өлшемі: {invoiceOrder.dimensions} • Материал: {invoiceOrder.material}</p>
              </div>

              {invoiceOrder.notes && (
                <div className="bg-slate-50 p-2.5 rounded border border-slate-100 italic text-slate-500 text-xxs">
                  "Ескертпе: {invoiceOrder.notes}"
                </div>
              )}

              <div className="border-t-2 border-dashed border-slate-350 my-3"></div>

              <div className="space-y-1.5 font-mono">
                <div className="flex justify-between">
                  <span>Жалпы құны:</span>
                  <span className="font-bold text-slate-800">{invoiceOrder.price.toLocaleString()} ₸</span>
                </div>
                <div className="flex justify-between text-teal-600">
                  <span>Енгізілген төлем:</span>
                  <span className="font-bold">-{invoiceOrder.paidAmount.toLocaleString()} ₸</span>
                </div>
                <div className="flex justify-between text-slate-900 border-t border-slate-100 pt-1.5 text-sm font-black">
                  <span>Төленетін қалдық:</span>
                  <span>{(invoiceOrder.price - invoiceOrder.paidAmount).toLocaleString()} ₸</span>
                </div>
              </div>

              <div className="border-t border-dashed border-slate-200 my-2 pt-4 flex justify-between items-center">
                <div className="text-center w-1/2 border-r border-slate-100">
                  <span className="text-xxs text-slate-400 block mb-4">Жауапты менеджер қолы</span>
                  <div className="w-16 h-px bg-slate-400 mx-auto"></div>
                </div>
                <div className="text-center w-1/2">
                  <span className="text-xxs text-slate-400 block mb-4">Клиент қолы</span>
                  <div className="w-16 h-px bg-slate-400 mx-auto"></div>
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="flex gap-2 pt-2">
              <button
                onClick={() => {
                  window.print();
                }}
                className="flex-1 bg-slate-900 text-white font-bold text-xs py-2.5 rounded-xl cursor-pointer hover:bg-slate-850 transition"
              >
                Басып шығару (Печать)
              </button>
              <button
                onClick={() => setInvoiceOrder(null)}
                className="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs py-2.5 rounded-xl cursor-pointer transition"
              >
                Жабу
              </button>
            </div>

          </div>
        </div>
      )}

      {/* WhatsApp Template Builder Modal */}
      {whatsappOrder && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-6 max-w-xl w-full border border-slate-100 dark:border-slate-800 shadow-2xl relative space-y-4">
            
            <div className="flex justify-between items-center pb-2 border-b border-slate-100 dark:border-slate-800">
              <div>
                <h3 className="font-black text-slate-800 dark:text-white text-sm uppercase tracking-wider flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
                  🟢 WhatsApp Клиенттік Хабарламалар
                </h3>
                <p className="text-xxs text-slate-500">Клиент {whatsappOrder.clientName} үшін хабарлама шаблоны</p>
              </div>
              <button 
                onClick={() => setWhatsappOrder(null)} 
                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-lg cursor-pointer font-bold"
              >
                ✕
              </button>
            </div>

            {/* Template Selector Grid */}
            <div className="space-y-1.5">
              <label className="text-xxs font-bold text-slate-400 uppercase tracking-wider block">Шаблонды таңдау:</label>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {[
                  { id: 'accepted', label: 'Қабылданды', color: 'border-blue-200 dark:border-blue-800/30' },
                  { id: 'measurement', label: 'Өлшеу (Замер)', color: 'border-indigo-200 dark:border-indigo-800/30' },
                  { id: 'production', label: 'Өндірісте', color: 'border-amber-200 dark:border-amber-800/30' },
                  { id: 'ready', label: 'Дайын / Жеткізу', color: 'border-purple-200 dark:border-purple-800/30' },
                  { id: 'completed', label: 'Аяқталды', color: 'border-emerald-200 dark:border-emerald-800/30' }
                ].map(t => (
                  <button
                    key={t.id}
                    onClick={() => setSelectedTemplate(t.id)}
                    className={`p-2 rounded-xl border text-center text-[10px] font-bold transition cursor-pointer ${
                      selectedTemplate === t.id
                        ? 'bg-emerald-600 border-emerald-600 text-white shadow-sm'
                        : 'bg-slate-50 dark:bg-slate-950/40 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-900 ' + t.color
                    }`}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Editable Text Area */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center">
                <label className="text-xxs font-bold text-slate-400 uppercase tracking-wider block">Хабарлама мәтіні (өзгертуге болады):</label>
                <span className="text-[9px] font-bold text-slate-400 font-mono">Символ саны: {whatsappMessageText.length}</span>
              </div>
              <textarea
                value={whatsappMessageText}
                onChange={(e) => setWhatsappMessageText(e.target.value)}
                className="w-full h-44 p-3.5 bg-slate-50 dark:bg-slate-950/40 border border-slate-200 dark:border-slate-850 rounded-xl text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500 font-sans leading-relaxed"
                placeholder="Хабарлама мәтіні..."
              />
            </div>

            {/* Client Info and Actions */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 bg-slate-50 dark:bg-slate-950/30 p-3 rounded-2xl border border-slate-150 dark:border-slate-850">
              <div className="text-xxs">
                <p className="text-slate-400 font-bold uppercase tracking-wider">Алушы телефоны:</p>
                <p className="font-extrabold text-slate-800 dark:text-slate-100 font-mono mt-0.5 text-xs">{whatsappOrder.clientPhone}</p>
              </div>
              <div className="flex gap-2 w-full sm:w-auto">
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(whatsappMessageText);
                    onShowToast('Мәтін алмасу буферіне көшірілді! 📋');
                  }}
                  className="flex-1 sm:flex-none bg-slate-100 hover:bg-slate-200 dark:bg-slate-850 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 font-bold text-xxs px-4 py-2.5 rounded-xl transition cursor-pointer"
                >
                  Көшіру
                </button>
                <button
                  onClick={() => {
                    const cleanPhone = getCleanPhoneForWhatsApp(whatsappOrder.clientPhone);
                    const encodedText = encodeURIComponent(whatsappMessageText);
                    const url = `https://wa.me/${cleanPhone}?text=${encodedText}`;
                    window.open(url, '_blank');
                    onShowToast('WhatsApp ашылуда...');
                  }}
                  className="flex-1 sm:flex-none bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xxs px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 transition cursor-pointer shadow-sm"
                >
                  <Smartphone className="w-3.5 h-3.5" />
                  WhatsApp-қа жіберу
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* Cost Breakdown & Profit Calculator Modal */}
      {calculatingOrder && (() => {
        const matCost = (Number(woodSheetsCount) * Number(woodSheetPrice)) + (Number(edgeMeters) * Number(edgePrice)) + Number(fittingsCost);
        const totalEstimatedCost = matCost + Number(laborCostState) + Number(overheadCost);
        const calcNetProfit = calculatingOrder.price - totalEstimatedCost;
        const calcMargin = calculatingOrder.price > 0 ? (calcNetProfit / calculatingOrder.price) * 100 : 0;
        
        return (
          <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto animate-fadeIn">
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-6 max-w-2xl w-full border border-slate-100 dark:border-slate-800 shadow-2xl relative space-y-5 max-h-[95vh] overflow-y-auto">
              
              <div className="flex justify-between items-center pb-2 border-b border-slate-100 dark:border-slate-800">
                <div>
                  <h3 className="font-black text-slate-800 dark:text-white text-sm uppercase tracking-wider flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-pulse" />
                    📊 Өзіндік құн және Пайда калькуляторы
                  </h3>
                  <p className="text-xxs text-slate-500">Тапсырыс: <span className="font-bold text-slate-700 dark:text-slate-300">{calculatingOrder.productType}</span> ({calculatingOrder.id})</p>
                </div>
                <button 
                  onClick={() => setCalculatingOrder(null)} 
                  className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-205 text-lg cursor-pointer font-bold bg-slate-50 dark:bg-slate-950/40 w-7 h-7 rounded-full flex items-center justify-center"
                >
                  ✕
                </button>
              </div>

              {/* Grid of Inputs */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                
                {/* 1. Wood Sheets */}
                <div className="space-y-1.5 bg-slate-50 dark:bg-slate-950/20 p-3 rounded-2xl border border-slate-100 dark:border-slate-850">
                  <span className="text-xxs font-black text-slate-400 uppercase block">1. Ағаш тақталар (ЛДСП/МДФ)</span>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Саны (дана)</label>
                      <input 
                        type="number"
                        value={woodSheetsCount}
                        onChange={(e) => setWoodSheetsCount(e.target.value)}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-2.5 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Дана бағасы (₸)</label>
                      <input 
                        type="number"
                        value={woodSheetPrice}
                        onChange={(e) => setWoodSheetPrice(e.target.value)}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-2.5 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                      />
                    </div>
                  </div>
                  <div className="text-[10px] text-right text-slate-400 font-mono font-bold mt-1">
                    Қорытынды: {(Number(woodSheetsCount) * Number(woodSheetPrice)).toLocaleString()} ₸
                  </div>
                </div>

                {/* 2. Edges */}
                <div className="space-y-1.5 bg-slate-50 dark:bg-slate-950/20 p-3 rounded-2xl border border-slate-100 dark:border-slate-850">
                  <span className="text-xxs font-black text-slate-400 uppercase block">2. Жиек таспасы (Кромка)</span>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Ұзындығы (метр)</label>
                      <input 
                        type="number"
                        value={edgeMeters}
                        onChange={(e) => setEdgeMeters(e.target.value)}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-2.5 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Метр бағасы (₸)</label>
                      <input 
                        type="number"
                        value={edgePrice}
                        onChange={(e) => setEdgePrice(e.target.value)}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-2.5 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                      />
                    </div>
                  </div>
                  <div className="text-[10px] text-right text-slate-400 font-mono font-bold mt-1">
                    Қорытынды: {(Number(edgeMeters) * Number(edgePrice)).toLocaleString()} ₸
                  </div>
                </div>

                {/* 3. Fittings */}
                <div className="space-y-1.5 bg-slate-50 dark:bg-slate-950/20 p-3 rounded-2xl border border-slate-100 dark:border-slate-850">
                  <span className="text-xxs font-black text-slate-400 uppercase block">3. Фурнитура & Аксессуарлар (₸)</span>
                  <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Петли, бағыттағыштар, тұтқалар жалпы құны</label>
                  <input 
                    type="number"
                    value={fittingsCost}
                    onChange={(e) => setFittingsCost(e.target.value)}
                    className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                  />
                </div>

                {/* 4. Labor Cost */}
                <div className="space-y-1.5 bg-slate-50 dark:bg-slate-950/20 p-3 rounded-2xl border border-slate-100 dark:border-slate-850">
                  <span className="text-xxs font-black text-slate-400 uppercase block">4. Шебердің Еңбекақысы (₸)</span>
                  <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Аралаушы мен құрастырушы маман үлесі</label>
                  <input 
                    type="number"
                    value={laborCostState}
                    onChange={(e) => setLaborCostState(e.target.value)}
                    className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                  />
                </div>

                {/* 5. Overhead cost */}
                <div className="space-y-1.5 bg-slate-50 dark:bg-slate-950/20 p-3 rounded-2xl border border-slate-100 dark:border-slate-850 sm:col-span-2">
                  <span className="text-xxs font-black text-slate-400 uppercase block">5. Көлік және басқа да үстеме шығындар (₸)</span>
                  <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Жеткізу, орнату, цех амортизациясы мен электр қуатының үлесі</label>
                  <input 
                    type="number"
                    value={overheadCost}
                    onChange={(e) => setOverheadCost(e.target.value)}
                    className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-indigo-500 font-mono"
                  />
                </div>

              </div>

              {/* LIVE ANALYTICS PANEL */}
              <div className="p-4 bg-slate-950 text-white rounded-3xl border border-slate-800 space-y-3.5 relative overflow-hidden">
                <div className="absolute right-[-20px] bottom-[-20px] w-32 h-32 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none" />
                
                <h4 className="text-xxs font-extrabold uppercase tracking-widest text-indigo-400 flex items-center gap-1">
                  <Sparkles className="w-3.5 h-3.5 text-indigo-400 animate-pulse" />
                  Шеберхананың Пайда Есептемесі
                </h4>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                  <div className="bg-slate-900/60 p-2.5 rounded-2xl border border-slate-900">
                    <span className="text-[9px] text-slate-400 block uppercase font-bold">Тапсырыс құны</span>
                    <span className="text-xs font-black font-mono text-white">{calculatingOrder.price.toLocaleString()} ₸</span>
                  </div>
                  <div className="bg-slate-900/60 p-2.5 rounded-2xl border border-slate-900">
                    <span className="text-[9px] text-slate-400 block uppercase font-bold">Материалдар</span>
                    <span className="text-xs font-black font-mono text-slate-300">{matCost.toLocaleString()} ₸</span>
                  </div>
                  <div className="bg-slate-900/60 p-2.5 rounded-2xl border border-slate-900">
                    <span className="text-[9px] text-slate-400 block uppercase font-bold">Өзіндік құны</span>
                    <span className="text-xs font-black font-mono text-slate-300">{totalEstimatedCost.toLocaleString()} ₸</span>
                  </div>
                  <div className="p-2.5 rounded-2xl border border-indigo-950 bg-indigo-950/25">
                    <span className="text-[9px] text-indigo-300 block uppercase font-bold">Таза пайда</span>
                    <span className={`text-xs font-black font-mono ${calcNetProfit >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                      {calcNetProfit >= 0 ? '+' : ''}{calcNetProfit.toLocaleString()} ₸
                    </span>
                  </div>
                </div>

                <div className="border-t border-slate-900 pt-3 flex flex-col sm:flex-row justify-between items-center gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xxs text-slate-400">Рентабельділік коэффициенті (Маржа):</span>
                    <span className={`px-2 py-0.5 rounded-full text-xxs font-black font-mono ${
                      calcMargin >= 35 ? 'bg-emerald-500/20 text-emerald-400' :
                      calcMargin >= 15 ? 'bg-amber-500/20 text-amber-400' : 'bg-rose-500/20 text-rose-400'
                    }`}>
                      {Math.round(calcMargin)}%
                    </span>
                  </div>
                  <div className="text-xxs font-bold text-slate-300">
                    {calcMargin >= 35 ? '🟢 Өте жоғары пайдалық деңгей' :
                     calcMargin >= 15 ? '🟡 Нормаланған пайдалық деңгей' : '🔴 Шұғыл шығындарды азайту қажет!'}
                  </div>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex gap-2.5 pt-2 border-t border-slate-150 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => {
                    const cb = {
                      woodSheetsCount: Number(woodSheetsCount) || 0,
                      woodSheetPrice: Number(woodSheetPrice) || 0,
                      edgeMeters: Number(edgeMeters) || 0,
                      edgePrice: Number(edgePrice) || 0,
                      fittingsCost: Number(fittingsCost) || 0,
                      laborCost: Number(laborCostState) || 0,
                      overheadCost: Number(overheadCost) || 0
                    };
                    onUpdateOrder({
                      ...calculatingOrder,
                      costBreakdown: cb
                    });
                    onShowToast(`Өзіндік құн мен пайда есебі сақталды! 💰`);
                    setCalculatingOrder(null);
                  }}
                  className="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs py-3 rounded-xl flex items-center justify-center gap-1.5 transition cursor-pointer shadow-sm active:scale-98"
                >
                  <Coins className="w-4 h-4" />
                  Есепті сақтау және жаңарту
                </button>
                <button
                  type="button"
                  onClick={() => setCalculatingOrder(null)}
                  className="bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-300 font-bold text-xs px-6 py-3 rounded-xl transition cursor-pointer"
                >
                  Болдырмау
                </button>
              </div>

            </div>
          </div>
        );
      })()}

      {/* Contract & Agreement Generator Modal */}
      {contractOrder && (() => {
        const remaining = contractOrder.price - contractOrder.paidAmount;
        const dateFormatted = new Date(contractOrder.createdAt).toLocaleDateString('kk-KZ');

        const getStageWhatsAppMessage = (stage: string) => {
          switch (stage) {
            case 'new':
              return `Қайырлы күн, ${contractOrder.clientName}!\n\nJUMA UI MEBEL шеберханасы. Сізбен № ${contractOrder.id} ресми дайындау шарты жасалды.\n\n📄 Шарт бөлшектері:\n- Бұйым: ${contractOrder.productType}\n- Жалпы құны: ${contractOrder.price.toLocaleString()} ₸\n- Алдын ала төленді: ${contractOrder.paidAmount.toLocaleString()} ₸\n- Қалдық сома: ${remaining.toLocaleString()} ₸\n- Орындау мерзімі: ${contractTermsDays} жұмыс күні\n- Сапа кепілдігі: ${contractWarrantyMonths} ай\n- Клиент ЖСН: ${clientIin || '_________________'}\n\nСұрақтар туындаса, осы нөмірге хабарласыңыз! 🛋️✨`;
            case 'measurement':
              return `Қайырлы күн, ${contractOrder.clientName}!\n\n📐 № ${contractOrder.id} шарты бойынша өлшем алу (замер) кезеңі сәтті өтті.\n\nБұйым өлшемдері нақтыланып, сызбасы цехқа жолданды. Жоспарлы орындау мерзімі (${contractTermsDays} жұмыс күні) басталды.\n\nРақмет, JUMA UI MEBEL.`;
            case 'production':
              return `Қайырлы күн, ${contractOrder.clientName}!\n\n🔨 № ${contractOrder.id} шарты бойынша тапсырысыңыз цехта белсенді өндіріс кезеңінде.\nМатериалдар пішіліп, фурнитуралар дайындалуда. Біз әр бөлшектің сапасына ерекше мән береміз.\n\nКүніңіз сәтті өтсін! JUMA UI MEBEL.`;
            case 'delivery':
              return `Қайырлы күн, ${contractOrder.clientName}!\n\n🚚 Жағымды жаңалық! № ${contractOrder.id} шарты бойынша "${contractOrder.productType}" жиһазыңыз толық дайын болып, жеткізу бригадасына берілді.\n\nЖеткізу мен орнату уақытын келісу үшін бізге жауап жазуыңызды сұраймыз.\n\n💳 Жеткізу алдындағы төлем қалдығы: ${remaining.toLocaleString()} ₸.\nJUMA UI MEBEL.`;
            case 'completed':
              return `Қайырлы күн, ${contractOrder.clientName}!\n\n✨ № ${contractOrder.id} келісімшарты бойынша жұмыстар 100% аяқталды және орнатылды.\n\nОсы сәттен бастап сіздің бұйымыңызға ${contractWarrantyMonths} айлық ресми сапа кепілдігі өз күшіне енді.\n\nСенім білдіргеніңізге рақмет! Бұйымыңыз құтты болсын! 🛋️💖`;
            default:
              return '';
          }
        };

        const activeMsgText = getStageWhatsAppMessage(contractActiveTab);

        return (
          <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto animate-fadeIn">
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-6 max-w-5xl w-full border border-slate-100 dark:border-slate-800 shadow-2xl relative space-y-6 max-h-[95vh] overflow-y-auto">
              
              {/* Header */}
              <div className="flex justify-between items-center pb-3 border-b border-slate-100 dark:border-slate-800">
                <div>
                  <h3 className="font-black text-slate-800 dark:text-white text-sm uppercase tracking-wider flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-blue-500 animate-pulse" />
                    📄 Келісімшарт (Договор) жасау орталығы
                  </h3>
                  <p className="text-xxs text-slate-500">Тапсырыс беруші: <span className="font-bold text-slate-700 dark:text-slate-300">{contractOrder.clientName}</span> | Телефон: {contractOrder.clientPhone}</p>
                </div>
                <button 
                  onClick={() => setContractOrder(null)} 
                  className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-lg cursor-pointer font-bold bg-slate-50 dark:bg-slate-950/40 w-7 h-7 rounded-full flex items-center justify-center"
                >
                  ✕
                </button>
              </div>

              {/* Grid content */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
                
                {/* Left side: Configuration and Stage Sharing */}
                <div className="lg:col-span-5 space-y-5">
                  
                  {/* Part A: Contract Data */}
                  <div className="bg-slate-50 dark:bg-slate-950/20 p-4 rounded-2xl border border-slate-100 dark:border-slate-850 space-y-3.5">
                    <span className="text-xxs font-black text-slate-500 uppercase tracking-widest block font-sans">1. ШАРТ ДЕРЕКТЕРІ</span>
                    
                    <div>
                      <label className="text-[10px] font-bold text-slate-500 block mb-1">Клиент ЖСН (ИИН - 12 сан):</label>
                      <input 
                        type="text"
                        maxLength={12}
                        placeholder="Мысалы: 950812300456"
                        value={clientIin}
                        onChange={(e) => setClientIin(e.target.value.replace(/\D/g, ''))}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500 font-mono"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-[10px] font-bold text-slate-500 block mb-1">Орындау мерзімі (күн):</label>
                        <input 
                          type="number"
                          value={contractTermsDays}
                          onChange={(e) => setContractTermsDays(e.target.value)}
                          className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500 font-mono"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] font-bold text-slate-500 block mb-1">Кепілдік (ай):</label>
                        <input 
                          type="number"
                          value={contractWarrantyMonths}
                          onChange={(e) => setContractWarrantyMonths(e.target.value)}
                          className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] font-bold text-slate-500 block mb-1">Орындаушы (Сатушы мекеме):</label>
                      <input 
                        type="text"
                        value={contractSeller}
                        onChange={(e) => setContractSeller(e.target.value)}
                        className="w-full bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  {/* Part B: Stage Message Sender */}
                  <div className="bg-slate-50 dark:bg-slate-950/20 p-4 rounded-2xl border border-slate-100 dark:border-slate-850 space-y-3.5">
                    <span className="text-xxs font-black text-slate-500 uppercase tracking-widest block flex items-center gap-1 font-sans">
                      <Smartphone className="w-3.5 h-3.5 text-emerald-500 animate-bounce" />
                      2. КЛИЕНТКЕ ЖІБЕРУ КЕЗЕҢДЕРІ (ЛАҚТЫРУ)
                    </span>
                    
                    {/* Horizontal tabs */}
                    <div className="flex flex-wrap gap-1 bg-slate-200/50 dark:bg-slate-950/40 p-1 rounded-xl">
                      {[
                        { id: 'new', label: '1. Шарт/Қабылдау' },
                        { id: 'measurement', label: '2. Өлшеу' },
                        { id: 'production', label: '3. Өндіріс' },
                        { id: 'delivery', label: '4. Жеткізу' },
                        { id: 'completed', label: '5. Аяқтау' }
                      ].map((tab) => (
                        <button
                          key={tab.id}
                          type="button"
                          onClick={() => setContractActiveTab(tab.id)}
                          className={`flex-1 text-[9px] font-black py-1 px-1 rounded-lg transition text-center cursor-pointer ${
                            contractActiveTab === tab.id
                              ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white shadow-sm'
                              : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
                          }`}
                        >
                          {tab.label}
                        </button>
                      ))}
                    </div>

                    {/* Message Preview box */}
                    <div className="space-y-1.5">
                      <div className="flex justify-between items-center">
                        <span className="text-[10px] font-bold text-slate-400">WhatsApp хабарлама мәтіні:</span>
                        <span className="text-3xs bg-emerald-500/10 text-emerald-500 font-bold px-1.5 py-0.5 rounded-full font-mono uppercase">Дайын</span>
                      </div>
                      <textarea
                        readOnly
                        value={activeMsgText}
                        className="w-full h-36 bg-emerald-500/5 dark:bg-emerald-950/10 border border-emerald-500/20 dark:border-emerald-500/10 rounded-xl p-3 text-[11px] text-slate-800 dark:text-slate-100 font-sans focus:outline-none resize-none leading-relaxed"
                      />
                    </div>

                    {/* Share Action Button */}
                    <button
                      type="button"
                      onClick={() => {
                        const cleanPhone = getCleanPhoneForWhatsApp(contractOrder.clientPhone);
                        const whatsappUrl = `https://api.whatsapp.com/send?phone=${cleanPhone}&text=${encodeURIComponent(activeMsgText)}`;
                        window.open(whatsappUrl, '_blank');
                        onShowToast('WhatsApp-қа хабарлама сәтті жіберілді! 🚀');
                      }}
                      className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs py-2.5 rounded-xl flex items-center justify-center gap-1.5 transition cursor-pointer shadow-sm active:scale-98"
                    >
                      <MessageSquare className="w-4 h-4" />
                      Клиенттің WhatsApp-ына лақтыру
                    </button>

                  </div>

                </div>

                {/* Right side: Beautiful Paper Contract Preview */}
                <div className="lg:col-span-7 space-y-4">
                  <span className="text-xxs font-black text-slate-500 uppercase tracking-widest block font-sans">3. ШАРТТЫҢ КӨРІНІСІ (ҚҰЖАТ ҚАҒАЗЫ)</span>
                  
                  {/* Paper sheet */}
                  <div className="bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm max-h-[420px] overflow-y-auto space-y-4 text-[11px] font-serif leading-relaxed text-justify">
                    
                    <div className="text-center font-bold text-sm border-b border-slate-300 pb-2 mb-2 dark:border-slate-800 font-sans">
                      ЖИҺАЗ ДАЙЫНДАУ ЖӘНЕ САТЫП АЛУ-САТУ ШАРТЫ № {contractOrder.id}
                      <p className="text-[9px] font-sans font-normal text-slate-400 dark:text-slate-500 uppercase tracking-wide mt-1">Ресми заңды келісім шарт жобасы</p>
                    </div>

                    <div className="flex justify-between font-bold font-sans">
                      <span>Алматы қаласы</span>
                      <span>Күні: {dateFormatted} ж.</span>
                    </div>

                    <p>
                      Осы Келісімшарт бұдан әрі «Орындаушы» деп аталатын <b>{contractSeller || '«JUMA UI MEBEL»'}</b> атынан бір тараптан және бұдан әрі «Тапсырыс беруші» деп аталатын азамат(ша) <b>{contractOrder.clientName}</b> (ЖСН: <b>{clientIin || '_________________'}</b>, тел: <b>{contractOrder.clientPhone}</b>) екінші тараптан, төмендегілер туралы осы Шартты жасасты:
                    </p>

                    <div className="font-bold border-b border-slate-200 pb-0.5 dark:border-slate-800 font-sans">1. Шарттың мәні және сипаттамасы</div>
                    <p>
                      1.1. Орындаушы Тапсырыс берушінің тапсырысы бойынша және бекітілген өлшемдерге сәйкес келесі бұйымды дайындауға, жеткізуге және орнатуға міндеттенеді: <b>{contractOrder.productType}</b>.
                      <br />
                      1.2. Өлшемдері: {contractOrder.dimensions || 'Стандарт / Сызба бойынша'}. Материалы: {contractOrder.material || 'Таңдалмаған'}.
                    </p>

                    <div className="font-bold border-b border-slate-200 pb-0.5 dark:border-slate-800 font-sans">2. Төлем және баға</div>
                    <p>
                      2.1. Осы Шарт бойынша дайындалатын жиһаз бұйымының жалпы құны: <b>{contractOrder.price.toLocaleString()} ₸</b> құрайды.
                      <br />
                      2.2. Тапсырыс беруші Шартқа қол қойған сәтте жалпы соманың <b>{contractOrder.paidAmount.toLocaleString()} ₸</b> көлемінде кепілдік аванс енгізеді.
                      <br />
                      2.3. Тапсырыстың қалған сомасы <b>{remaining.toLocaleString()} ₸</b> бұйым толық дайын болып, жеткізіліп орнатылғаннан кейін Орындаушыға қолма-қол немесе аударым түрінде төленеді.
                    </p>

                    <div className="font-bold border-b border-slate-200 pb-0.5 dark:border-slate-800 font-sans">3. Орындау мерзімі</div>
                    <p>
                      3.1. Орындаушы тапсырысты Шарт жасалған және аванс төленген күннен бастап <b>{contractTermsDays} жұмыс күні</b> ішінде сапалы етіп дайындап, жеткізуге міндеттенеді.
                    </p>

                    <div className="font-bold border-b border-slate-200 pb-0.5 dark:border-slate-800 font-sans">4. Кепілдік міндеттемелер</div>
                    <p>
                      4.1. Орындаушы дайындалған жиһаз бұйымының сапасына <b>{contractWarrantyMonths} ай</b> көлемінде ресми кепілдік береді. Кепілдік бұйым орнатылған сәттен бастап есептеледі.
                    </p>

                    <div className="flex justify-between pt-4 text-[9px] border-t border-slate-200 dark:border-slate-800 font-sans">
                      <div>
                        <b>Орындаушы:</b>
                        <p className="mt-6">Қолы: _________________</p>
                      </div>
                      <div className="text-right">
                        <b>Тапсырыс беруші:</b>
                        <p className="mt-6">Қолы: _________________</p>
                      </div>
                    </div>

                  </div>

                  {/* Print trigger */}
                  <button
                    type="button"
                    onClick={() => handlePrintContract(contractOrder, clientIin, contractWarrantyMonths, contractTermsDays, contractSeller)}
                    className="w-full bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-300 font-bold text-xs py-2.5 rounded-xl flex items-center justify-center gap-1.5 transition cursor-pointer"
                  >
                    <Printer className="w-4 h-4 text-slate-500" />
                    Келісімшартты толық нұсқада басып шығару (A4 / Печать)
                  </button>

                </div>

              </div>

              {/* Save back and Finish */}
              <div className="flex gap-2.5 pt-3 border-t border-slate-150 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => {
                    // Update database
                    onUpdateOrder({
                      ...contractOrder,
                      clientIin: clientIin || undefined,
                      contractWarrantyMonths: Number(contractWarrantyMonths) || 12,
                      contractTermsDays: Number(contractTermsDays) || 15,
                      contractSeller: contractSeller
                    });
                    onShowToast(`Келісімшарт параметрлері сәтті сақталды! 📄✨`);
                    setContractOrder(null);
                  }}
                  className="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs py-3 rounded-xl flex items-center justify-center gap-1.5 transition cursor-pointer shadow-sm active:scale-98"
                >
                  <FileText className="w-4 h-4" />
                  Келісімшартты сақтау және жаңарту
                </button>
                <button
                  type="button"
                  onClick={() => setContractOrder(null)}
                  className="bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-300 font-bold text-xs px-6 py-3 rounded-xl transition cursor-pointer"
                >
                  Болдырмау
                </button>
              </div>

            </div>
          </div>
        );
      })()}

    </div>
  );
}
