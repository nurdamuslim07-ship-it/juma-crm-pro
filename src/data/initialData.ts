import { Order, Client, Product, InventoryItem, Employee, Measurement } from '../types';

export const INITIAL_ORDERS: Order[] = [
  {
    id: 'ORD-101',
    clientName: 'Нұрдаулет Смағұлов',
    clientPhone: '+7 701 555 1234',
    productType: 'Ас үй гарнитуры (Кухня)',
    material: 'МДФ Боялған (Ақ Жалтыр) + Blum петли',
    dimensions: '320х60х240 см',
    price: 950000,
    paidAmount: 950000,
    status: 'completed',
    createdAt: '2026-06-15T10:30:00Z',
    deliveryDate: '2026-06-25',
    notes: 'Ақ жалтыр фасадтар, біріктірілген тұтқалар (Gola профиль), Кварц столешница, барлық петли Blum.',
    employeeId: 'emp-1',
    costBreakdown: {
      woodSheetsCount: 6,
      woodSheetPrice: 28000,
      edgeMeters: 120,
      edgePrice: 400,
      fittingsCost: 210000,
      laborCost: 150000,
      overheadCost: 44000
    }
  },
  {
    id: 'ORD-102',
    clientName: 'Әлия Оспанова',
    clientPhone: '+7 707 333 4567',
    productType: 'Шкаф-купе (Wardrobe)',
    material: 'ЛДСП Egger (Сұр) + Айналы есік',
    dimensions: '220х65х250 см',
    price: 480000,
    paidAmount: 250000,
    status: 'production',
    productionStage: 'assembly',
    createdAt: '2026-06-24T14:15:00Z',
    deliveryDate: '2026-07-05',
    notes: 'Сол жақ есігі толық айна, оң жағы ЛДСП. Механизмдері баяу жабылатын (Hettich).',
    employeeId: 'emp-2',
    costBreakdown: {
      woodSheetsCount: 4,
      woodSheetPrice: 28000,
      edgeMeters: 60,
      edgePrice: 400,
      fittingsCost: 65000,
      laborCost: 80000,
      overheadCost: 29000
    }
  },
  {
    id: 'ORD-103',
    clientName: 'Арман Ибраев',
    clientPhone: '+7 747 444 8899',
    productType: 'Кіреберіс жиһазы (Прихожая)',
    material: 'МДФ Шпон + ЛДСП Кронноспан',
    dimensions: '180х45х230 см',
    price: 320000,
    paidAmount: 160000,
    status: 'delivery',
    createdAt: '2026-06-20T09:00:00Z',
    deliveryDate: '2026-07-01',
    notes: 'Ашық ілгіштері бар, жұмсақ отырғыш пен аяқ киім тартпалары қарастырылған.',
    employeeId: 'emp-5',
    costBreakdown: {
      woodSheetsCount: 3,
      woodSheetPrice: 28000,
      edgeMeters: 45,
      edgePrice: 400,
      fittingsCost: 35000,
      laborCost: 60000,
      overheadCost: 13000
    }
  },
  {
    id: 'ORD-104',
    clientName: 'Динара Төлеуова',
    clientPhone: '+7 702 777 3344',
    productType: 'Гардероб бөлмесі (Walk-in)',
    material: 'ЛДСП Премиум (Темір торлы сөрелер)',
    dimensions: '400х220х260 см',
    price: 1200000,
    paidAmount: 600000,
    status: 'measurement',
    createdAt: '2026-06-28T11:45:00Z',
    deliveryDate: '2026-07-15',
    notes: 'Замер толық алынды. Клиентпен сөрелер сызбасы бекітілді. Тартпа саны: 8 дана.',
    employeeId: 'emp-4',
    costBreakdown: {
      woodSheetsCount: 10,
      woodSheetPrice: 28000,
      edgeMeters: 180,
      edgePrice: 400,
      fittingsCost: 190000,
      laborCost: 200000,
      overheadCost: 58000
    }
  }
];

export const INITIAL_CLIENTS: Client[] = [
  {
    id: 'CLI-001',
    name: 'Нұрдаулет Смағұлов',
    phone: '+7 701 555 1234',
    email: 'nurda.s@gmail.com',
    address: 'Алматы қ., Достық даңғылы, 120, 15-пәтер',
    totalOrders: 1,
    totalSpent: 950000,
    createdAt: '2026-06-15T10:30:00Z',
    notes: 'Тұрақты клиент. Премиум сапаны, Blum фурнитурасын ұнатады.'
  },
  {
    id: 'CLI-002',
    name: 'Әлия Оспанова',
    phone: '+7 707 333 4567',
    email: 'aliya.ospan@mail.ru',
    address: 'Астана қ., Мәңгілік Ел даңғылы, 25, 42-пәтер',
    totalOrders: 1,
    totalSpent: 480000,
    createdAt: '2026-06-24T14:15:00Z',
    notes: 'Дизайнға өте ұқыпты қарайды. Сұр емен реңктерін қалады.'
  },
  {
    id: 'CLI-003',
    name: 'Арман Ибраев',
    phone: '+7 747 444 8899',
    email: 'arman_ibraev@outlook.com',
    address: 'Шымкент қ., Қонаев бульвары, 4, 18-үй',
    totalOrders: 1,
    totalSpent: 320000,
    createdAt: '2026-06-20T09:00:00Z',
    notes: 'Шпон сапасына ерекше мән береді.'
  },
  {
    id: 'CLI-004',
    name: 'Динара Төлеуова',
    phone: '+7 702 777 3344',
    address: 'Алматы қ., Төле би көшесі, 45, 8-пәтер',
    totalOrders: 1,
    totalSpent: 1200000,
    createdAt: '2026-06-28T11:45:00Z'
  }
];

export const INITIAL_PRODUCTS: Product[] = [
  {
    id: 'PROD-001',
    name: 'Ас үй гарнитуры (Кухня)',
    category: 'custom',
    basePrice: 850000,
    description: 'МДФ фасадтары бар заманауи немесе классикалық ас үй гарнитуры',
    materials: ['МДФ Боялған', 'МДФ Пленка', 'Акрил', 'Шпон']
  },
  {
    id: 'PROD-002',
    name: 'Шкаф-купе (Wardrobe)',
    category: 'wardrobe',
    basePrice: 450000,
    description: 'Жылжымалы немесе топсалы есіктері бар ыңғайлы шкаф',
    materials: ['ЛДСП Egger', 'ЛДСП Kronospan', 'Айналы фасад']
  },
  {
    id: 'PROD-003',
    name: 'Кіреберіс жиһазы (Прихожая)',
    category: 'custom',
    basePrice: 280000,
    description: 'Дәлізге арналған ыңғайлы ілгіштер, аяқ киім шкафы мен отырғыш жиынтығы',
    materials: ['ЛДСП', 'МДФ фасад', 'Шпон']
  },
  {
    id: 'PROD-004',
    name: 'ТД тумбасы немесе Комод',
    category: 'custom',
    basePrice: 120000,
    description: 'Қонақ бөлмеге арналған талғампаз қысқа комод немесе консоль',
    materials: ['ЛДСП Egger', 'МДФ боялған']
  }
];

export const INITIAL_INVENTORY: InventoryItem[] = [
  {
    id: 'INV-001',
    name: 'ЛДСП Egger плитасы (Сұр емен, 18мм)',
    category: 'wood',
    quantity: 45,
    unit: 'плита',
    minQuantity: 10,
    costPerUnit: 18500
  },
  {
    id: 'INV-002',
    name: 'МДФ Қапталған Плита (Бояуға дайын, 16мм)',
    category: 'wood',
    quantity: 32,
    unit: 'плита',
    minQuantity: 8,
    costPerUnit: 22000
  },
  {
    id: 'INV-003',
    name: 'Blum баяу жабылатын топса (Австрия)',
    category: 'hardware',
    quantity: 180,
    unit: 'дана',
    minQuantity: 50,
    costPerUnit: 1450
  },
  {
    id: 'INV-004',
    name: 'Rehau ПВХ Кромка клейімен (2мм)',
    category: 'accessories',
    quantity: 450,
    unit: 'метр',
    minQuantity: 100,
    costPerUnit: 350
  },
  {
    id: 'INV-005',
    name: 'Кварц тас Столешница тақтасы',
    category: 'material',
    quantity: 12,
    unit: 'дана',
    minQuantity: 3,
    costPerUnit: 65000
  },
  {
    id: 'INV-006',
    name: 'Направляющие Blum тартпа механизмі (500мм)',
    category: 'hardware',
    quantity: 40,
    unit: 'комплект',
    minQuantity: 10,
    costPerUnit: 12000
  },
  {
    id: 'INV-007',
    name: 'Қара профильді есік тұтқалары (40см)',
    category: 'accessories',
    quantity: 95,
    unit: 'дана',
    minQuantity: 20,
    costPerUnit: 1100
  }
];

export const INITIAL_EMPLOYEES: Employee[] = [
  {
    id: 'emp-1',
    name: 'Бауыржан Серіков',
    role: 'carpenter', // Тілші / Распилщик (Распил станогының операторы)
    phone: '+7 701 111 2233',
    activeTasks: 1,
    completedTasks: 42,
    totalBonuses: 85000
  },
  {
    id: 'emp-2',
    name: 'Данияр Жұмашев',
    role: 'upholsterer', // Құрастырушы / Кромкалаушы
    phone: '+7 702 333 4455',
    activeTasks: 2,
    completedTasks: 35,
    totalBonuses: 110000
  },
  {
    id: 'emp-3',
    name: 'Ақбота Төлеген',
    role: 'designer', // Дизайнер-конструктор (Сызба жасаушы)
    phone: '+7 777 555 6677',
    activeTasks: 0,
    completedTasks: 18,
    totalBonuses: 45000
  },
  {
    id: 'emp-4',
    name: 'Мұрат Қасымов',
    role: 'measurer', // Өлшеуші маман (Замерщик)
    phone: '+7 747 888 9900',
    activeTasks: 1,
    completedTasks: 29,
    totalBonuses: 30000
  },
  {
    id: 'emp-5',
    name: 'Төлеген Батырхан',
    role: 'courier', // Жеткізуші және орнатушы (Установка)
    phone: '+7 707 999 0011',
    activeTasks: 1,
    completedTasks: 50,
    totalBonuses: 25000
  }
];

export const INITIAL_MEASUREMENTS: Measurement[] = [
  {
    id: 'MEA-001',
    clientName: 'Динара Төлеуова',
    phone: '+7 702 777 3344',
    address: 'Алматы қ., Төле би көшесі, 45, 8-пәтер',
    date: '2026-07-02',
    status: 'pending',
    notes: 'Ас үй гарнитуры мен кіріктірілген шкафқа өлшем алу қажет. Газ құбырлары мен розеткаларды белгілеу керек.'
  },
  {
    id: 'MEA-002',
    clientName: 'Сәкен Сәдуақас',
    phone: '+7 747 111 2222',
    address: 'Алматы қ., Сейфуллин көшесі, 182, 10-пәтер',
    date: '2026-06-29',
    status: 'completed',
    notes: 'Шкаф-купе орны өлшенді. Ені 220 см, тереңдігі 65 см, биіктігі 255 см бос тауаша (ниша) бар.',
    width: 220,
    depth: 65,
    height: 255,
    roomType: 'Дәліз (Прихожая)'
  }
];

// Helper to interact with Local Storage in a persistent way
export const loadLocalData = <T>(key: string, defaultValue: T): T => {
  try {
    const item = localStorage.getItem(`juma_crm_${key}`);
    return item ? JSON.parse(item) : defaultValue;
  } catch (error) {
    console.error(`Error loading localStorage key: juma_crm_${key}`, error);
    return defaultValue;
  }
};

export const saveLocalData = <T>(key: string, data: T): void => {
  try {
    localStorage.setItem(`juma_crm_${key}`, JSON.stringify(data));
  } catch (error) {
    console.error(`Error saving localStorage key: juma_crm_${key}`, error);
  }
};
