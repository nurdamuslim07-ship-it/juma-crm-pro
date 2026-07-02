/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useMemo } from 'react';
import { 
  Order, Client, InventoryItem, Employee, Measurement, OrderStatus, AppUser
} from './types';
import { 
  INITIAL_ORDERS, INITIAL_CLIENTS, INITIAL_INVENTORY, 
  INITIAL_EMPLOYEES, INITIAL_MEASUREMENTS, loadLocalData, saveLocalData 
} from './data/initialData';
import { 
  Layout, Users, Package, BarChart3, Users2, Compass, 
  Menu, Bell, Moon, Sun, Plus, DollarSign, ArrowRight, 
  LogOut, ShieldAlert, Monitor, PhoneCall, Smartphone, Sparkles,
  Database, TrendingUp, UsersRound, Box, CloudLightning, RefreshCw, CheckCircle2, AlertTriangle
} from 'lucide-react';

import { 
  saveDocToFirestore, 
  saveCollectionToFirestore, 
  loadCollectionFromFirestore,
  deleteDocFromFirestore
} from './lib/supabase';

import {
  initTelegramWebApp,
  getTelegramUser,
  isTelegramMiniApp,
  hapticFeedback
} from './lib/telegram';

import OrdersModule from './components/OrdersModule';
import ClientsModule from './components/ClientsModule';
import InventoryModule from './components/InventoryModule';
import EmployeesModule from './components/EmployeesModule';
import MeasurementsModule from './components/MeasurementsModule';
import ReportsModule from './components/ReportsModule';
import Visualizer3D from './components/Visualizer3D';

const STATUS_KAZAKH: Record<OrderStatus, string> = {
  new: 'Жаңа',
  measurement: 'Өлшеу (Замер)',
  production: 'Цехта (Өндірісте)',
  delivery: 'Жеткізуде',
  completed: 'Аяқталды',
  cancelled: 'Бас тартылды'
};

export default function App() {
  // Authentication State
  const [currentUser, setCurrentUser] = useState<AppUser | null>(() => loadLocalData<AppUser | null>('current_user', null));
  const [appUsers, setAppUsers] = useState<AppUser[]>([]);
  const [loginError, setLoginError] = useState('');
  const isLoggedIn = !!currentUser;

  // Login & Registration temporary input states
  const [authMode, setAuthMode] = useState<'login' | 'register'>('login');
  const [loginMethod, setLoginMethod] = useState<'email' | 'phone'>('email');
  
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPhone, setLoginPhone] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  
  const [registerName, setRegisterName] = useState('');
  const [registerEmail, setRegisterEmail] = useState('');
  const [registerPhone, setRegisterPhone] = useState('');
  const [registerRole, setRegisterRole] = useState<'director' | 'employee'>('employee');
  const [registerPassword, setRegisterPassword] = useState('');

  // App Database States
  const [orders, setOrders] = useState<Order[]>(() => loadLocalData<Order[]>('orders', INITIAL_ORDERS));
  const [clients, setClients] = useState<Client[]>(() => loadLocalData<Client[]>('clients', INITIAL_CLIENTS));
  const [inventory, setInventory] = useState<InventoryItem[]>(() => loadLocalData<InventoryItem[]>('inventory', INITIAL_INVENTORY));
  const [employees, setEmployees] = useState<Employee[]>(() => loadLocalData<Employee[]>('employees', INITIAL_EMPLOYEES));
  const [measurements, setMeasurements] = useState<Measurement[]>(() => loadLocalData<Measurement[]>('measurements', INITIAL_MEASUREMENTS));

  // Navigation and UI States
  const [activeTab, setActiveTab] = useState<'home' | 'orders' | 'clients' | 'inventory' | 'reports' | 'employees' | 'measurements' | '3d'>('home');
  const [isDarkMode, setIsDarkMode] = useState(() => loadLocalData<boolean>('dark_mode', true));
  const [sideMenuOpen, setSideMenuOpen] = useState(false);
  const [bottomSheetOpen, setBottomSheetOpen] = useState(false);
  const [bottomSheetType, setBottomSheetType] = useState<'add_fast' | 'stats_quick' | 'notifications' | 'order_detail'>('add_fast');
  const [selectedOrderDetail, setSelectedOrderDetail] = useState<Order | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [showAddOrderForm, setShowAddOrderForm] = useState(false);
  
  // Mobile viewport detection for Telegram Mini App styling
  const [isMobileViewport, setIsMobileViewport] = useState(false);

  // Telegram Mini App: @Juma_ui_bot арқылы ашылса, пайдаланушы деректерін аламыз
  const [telegramUser] = useState(() => getTelegramUser());
  const openedInTelegram = useMemo(() => isTelegramMiniApp(), []);

  useEffect(() => {
    initTelegramWebApp((isDark) => setIsDarkMode(isDark));
  }, []);

  // Telegram арқылы ашылса және телефон/telegramId бойынша тіркелген қолданушы
  // табылса — автоматты кіру (қайта пароль сұрамай)
  useEffect(() => {
    if (!openedInTelegram || !telegramUser || isLoggedIn || appUsers.length === 0) return;
    const matched = appUsers.find(u => u.telegramId === telegramUser.id);
    if (matched) {
      setCurrentUser(matched);
      triggerToast(`Қош келдіңіз, ${matched.name}! (Telegram арқылы)`);
    } else {
      // Тіркелу формасын Telegram атымен алдын ала толтыру
      setRegisterName(prev => prev || [telegramUser.first_name, telegramUser.last_name].filter(Boolean).join(' '));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [openedInTelegram, telegramUser, appUsers, isLoggedIn]);

  useEffect(() => {
    const handleResize = () => {
      setIsMobileViewport(window.innerWidth < 1024);
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
  // App settings
  const [viewLayout, setViewLayout] = useState<'split' | 'phone-only' | 'desktop-only'>('split');

  // Sync to local storage
  useEffect(() => {
    saveLocalData('current_user', currentUser);
    saveLocalData('logged_in', isLoggedIn);
  }, [currentUser, isLoggedIn]);

  // Load users from Firestore and seed if necessary
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const cloudUsers = await loadCollectionFromFirestore<AppUser>('users');
        if (cloudUsers.length === 0) {
          const DEFAULT_USERS: AppUser[] = [
            { id: 'usr-dir-1', name: 'Нұрдәулет', email: 'director@gmail.com', phone: '87771112222', role: 'director', password: '2606', createdAt: new Date().toISOString() },
            { id: 'usr-emp-1', name: 'Бақытжан', email: 'employee@gmail.com', phone: '87773334444', role: 'employee', password: '1111', createdAt: new Date().toISOString() },
          ];
          for (const u of DEFAULT_USERS) {
            await saveDocToFirestore('users', u);
          }
          setAppUsers(DEFAULT_USERS);
        } else {
          setAppUsers(cloudUsers);
        }
      } catch (err) {
        console.error('Error fetching users:', err);
        setAppUsers([
          { id: 'usr-dir-1', name: 'Нұрдәулет', email: 'director@gmail.com', phone: '87771112222', role: 'director', password: '2606', createdAt: new Date().toISOString() },
          { id: 'usr-emp-1', name: 'Бақытжан', email: 'employee@gmail.com', phone: '87773334444', role: 'employee', password: '1111', createdAt: new Date().toISOString() },
        ]);
      }
    };
    fetchUsers();
  }, []);

  useEffect(() => {
    saveLocalData('orders', orders);
  }, [orders]);

  useEffect(() => {
    saveLocalData('clients', clients);
  }, [clients]);

  useEffect(() => {
    saveLocalData('inventory', inventory);
  }, [inventory]);

  useEffect(() => {
    saveLocalData('employees', employees);
  }, [employees]);

  useEffect(() => {
    saveLocalData('measurements', measurements);
  }, [measurements]);

  useEffect(() => {
    saveLocalData('dark_mode', isDarkMode);
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDarkMode]);

  // --- FIREBASE CLOUD DATABASE SYNC ENGINE ---
  const [syncStatus, setSyncStatus] = useState<'idle' | 'syncing' | 'success' | 'error'>('idle');

  // Load from Cloud Database
  const syncFromCloud = async (silent = false) => {
    setSyncStatus('syncing');
    try {
      const cloudOrders = await loadCollectionFromFirestore<Order>('orders');
      const cloudClients = await loadCollectionFromFirestore<Client>('clients');
      const cloudInventory = await loadCollectionFromFirestore<InventoryItem>('inventory');
      const cloudEmployees = await loadCollectionFromFirestore<Employee>('employees');
      const cloudMeasurements = await loadCollectionFromFirestore<Measurement>('measurements');

      // Check if cloud collections are all empty (new database)
      if (
        cloudOrders.length === 0 && 
        cloudClients.length === 0 && 
        cloudInventory.length === 0 && 
        cloudEmployees.length === 0 && 
        cloudMeasurements.length === 0
      ) {
        if (!silent) {
          triggerToast('Бұлттық база жаңадан дайындалды! Алғашқы мәліметтер толтырылуда...');
        }
        // Upload current state to seed cloud
        await saveCollectionToFirestore('orders', orders);
        await saveCollectionToFirestore('clients', clients);
        await saveCollectionToFirestore('inventory', inventory);
        await saveCollectionToFirestore('employees', employees);
        await saveCollectionToFirestore('measurements', measurements);
        setSyncStatus('success');
        return;
      }

      // Merge / overwrite local states with cloud data
      if (cloudOrders.length > 0) setOrders(cloudOrders);
      if (cloudClients.length > 0) setClients(cloudClients);
      if (cloudInventory.length > 0) setInventory(cloudInventory);
      if (cloudEmployees.length > 0) setEmployees(cloudEmployees);
      if (cloudMeasurements.length > 0) setMeasurements(cloudMeasurements);

      setSyncStatus('success');
      if (!silent) {
        triggerToast('Бұлттық базамен толық синхрондау сәтті өтті! ☁️✅');
      }
    } catch (error) {
      console.error('Firebase sync error:', error);
      setSyncStatus('error');
      if (!silent) {
        triggerToast('Бұлттық базаға қосыла алмады. Жергілікті режимде жұмыс істеуде.');
      }
    }
  };

  // Push all local data to Cloud Database
  const pushLocalToCloud = async () => {
    setSyncStatus('syncing');
    try {
      await saveCollectionToFirestore('orders', orders);
      await saveCollectionToFirestore('clients', clients);
      await saveCollectionToFirestore('inventory', inventory);
      await saveCollectionToFirestore('employees', employees);
      await saveCollectionToFirestore('measurements', measurements);
      setSyncStatus('success');
      triggerToast('Жергілікті деректер бұлттық базаға толық сақталды! ☁️🚀');
    } catch (error) {
      console.error('Firebase push error:', error);
      setSyncStatus('error');
      triggerToast('Сақтау кезінде қате кетті. Интернет желісін тексеріңіз.');
    }
  };

  // Auto-sync on startup once logged in
  useEffect(() => {
    if (isLoggedIn) {
      syncFromCloud(true);
    }
  }, [isLoggedIn]);

  // Show dynamic system toast
  const triggerToast = (msg: string) => {
    setToastMessage(msg);
    hapticFeedback('light');
    setTimeout(() => {
      setToastMessage(null);
    }, 3000);
  };

  // Login handler
  const handleCustomLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError('');

    const trimmedEmail = loginEmail.trim().toLowerCase();
    const trimmedPhone = loginPhone.trim();
    const passwordToMatch = loginPassword;

    let foundUser: AppUser | undefined;

    if (loginMethod === 'email') {
      if (!trimmedEmail || !passwordToMatch) {
        setLoginError('Gmail / Email және құпия сөзді толтырыңыз');
        return;
      }
      foundUser = appUsers.find(u => u.email?.toLowerCase() === trimmedEmail && u.password === passwordToMatch);
    } else {
      if (!trimmedPhone || !passwordToMatch) {
        setLoginError('Телефон нөмірін және құпия сөзді толтырыңыз');
        return;
      }
      foundUser = appUsers.find(u => u.phone === trimmedPhone && u.password === passwordToMatch);
    }

    if (foundUser) {
      setCurrentUser(foundUser);
      setLoginPassword('');
      triggerToast(`Қош келдіңіз, ${foundUser.name}! (${foundUser.role === 'director' ? 'Директор' : 'Қызметкер'})`);
    } else {
      setLoginError('Қате мәлімет немесе мұндай қолданушы жоқ!');
      triggerToast('Кіру қателігі');
    }
  };

  const handleCustomRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError('');

    if (!registerName.trim()) {
      setLoginError('Аты-жөніңізді толтырыңыз');
      return;
    }
    if (loginMethod === 'email' && !registerEmail.trim()) {
      setLoginError('Gmail / Email мекен-жайын жазыңыз');
      return;
    }
    if (loginMethod === 'phone' && !registerPhone.trim()) {
      setLoginError('Телефон нөмірін жазыңыз');
      return;
    }
    if (!registerPassword) {
      setLoginError('Құпия сөзді енгізіңіз');
      return;
    }

    // Check duplicates
    if (loginMethod === 'email') {
      const emailExists = appUsers.some(u => u.email?.toLowerCase() === registerEmail.trim().toLowerCase());
      if (emailExists) {
        setLoginError('Бұл Gmail / Email жүйеде тіркелген!');
        return;
      }
    } else {
      const phoneExists = appUsers.some(u => u.phone === registerPhone.trim());
      if (phoneExists) {
        setLoginError('Бұл телефон нөмірі жүйеде тіркелген!');
        return;
      }
    }

    const newUser: AppUser = {
      id: `usr-${Math.floor(1000 + Math.random() * 9000)}`,
      name: registerName.trim(),
      email: loginMethod === 'email' ? registerEmail.trim().toLowerCase() : '',
      phone: loginMethod === 'phone' ? registerPhone.trim() : '',
      role: registerRole,
      password: registerPassword,
      createdAt: new Date().toISOString(),
      ...(openedInTelegram && telegramUser
        ? { telegramId: telegramUser.id, telegramUsername: telegramUser.username }
        : {})
    };

    try {
      await saveDocToFirestore('users', newUser);
      setAppUsers(prev => [...prev, newUser]);
      setCurrentUser(newUser);
      
      setRegisterName('');
      setRegisterEmail('');
      setRegisterPhone('');
      setRegisterPassword('');
      triggerToast(`Тіркелу сәтті! Қош келдіңіз, ${newUser.name}!`);
    } catch (error) {
      console.error('Registration error:', error);
      setLoginError('Базаға қосылу қатесі. Қайта көріңіз.');
    }
  };

  const handleLogout = () => {
    setCurrentUser(null);
    triggerToast('Жүйеден шықтыңыз');
  };

  // Helper callbacks to add/update database entries
  const addOrder = (newOrder: Order) => {
    setOrders([newOrder, ...orders]);
    saveDocToFirestore('orders', newOrder).catch(console.error);
    
    // Automatically update or register client if not exists
    const clientExists = clients.some(c => c.name.toLowerCase() === newOrder.clientName.toLowerCase());
    if (!clientExists) {
      const newClient: Client = {
        id: `CLI-${Math.floor(100 + Math.random() * 900)}`,
        name: newOrder.clientName,
        phone: newOrder.clientPhone,
        address: 'Шеберханада көрсетіледі',
        totalOrders: 1,
        totalSpent: newOrder.price,
        createdAt: new Date().toISOString()
      };
      setClients(prev => [newClient, ...prev]);
      saveDocToFirestore('clients', newClient).catch(console.error);
    } else {
      setClients(prev => prev.map(c => {
        if (c.name.toLowerCase() === newOrder.clientName.toLowerCase()) {
          const updatedClient = {
            ...c,
            totalOrders: c.totalOrders + 1,
            totalSpent: c.totalSpent + newOrder.price
          };
          saveDocToFirestore('clients', updatedClient).catch(console.error);
          return updatedClient;
        }
        return c;
      }));
    }
  };

  const updateOrder = (updated: Order) => {
    setOrders(prev => prev.map(o => o.id === updated.id ? updated : o));
    saveDocToFirestore('orders', updated).catch(console.error);
    
    // If completed, update employee bonuses
    if (updated.status === 'completed' && updated.employeeId) {
      const bonusEarned = Math.round(updated.price * 0.05); // 5% standard craftsmen bonus
      rewardEmployeeBonus(updated.employeeId, bonusEarned);
    }
  };

  const deleteOrder = (id: string) => {
    setOrders(prev => prev.filter(o => o.id !== id));
    deleteDocFromFirestore('orders', id).catch(console.error);
  };

  const addClient = (newClient: Client) => {
    setClients([newClient, ...clients]);
    saveDocToFirestore('clients', newClient).catch(console.error);
  };

  const updateInventory = (updatedItem: InventoryItem) => {
    setInventory(prev => prev.map(item => item.id === updatedItem.id ? updatedItem : item));
    saveDocToFirestore('inventory', updatedItem).catch(console.error);
  };

  const rewardEmployeeBonus = (empId: string, amount: number) => {
    setEmployees(prev => prev.map(emp => {
      if (emp.id === empId) {
        const updatedEmp = {
          ...emp,
          totalBonuses: emp.totalBonuses + amount,
          completedTasks: emp.completedTasks + 1,
          activeTasks: Math.max(0, emp.activeTasks - 1)
        };
        saveDocToFirestore('employees', updatedEmp).catch(console.error);
        return updatedEmp;
      }
      return emp;
    }));
  };

  const addMeasurement = (newMea: Measurement) => {
    setMeasurements([newMea, ...measurements]);
    saveDocToFirestore('measurements', newMea).catch(console.error);
  };

  const updateMeasurement = (updated: Measurement) => {
    setMeasurements(prev => prev.map(m => m.id === updated.id ? updated : m));
    saveDocToFirestore('measurements', updated).catch(console.error);
  };

  // Financial statistics calculated dynamically
  const financialStats = useMemo(() => {
    const activeOrders = orders.filter(o => o.status !== 'cancelled');
    const totalRevenue = activeOrders.reduce((sum, o) => sum + o.price, 0);
    const totalPaid = activeOrders.reduce((sum, o) => sum + o.paidAmount, 0);
    const activeCount = orders.filter(o => o.status === 'new' || o.status === 'production' || o.status === 'delivery').length;
    const newClientsThisMonth = clients.length;

    return {
      totalRevenue,
      totalPaid,
      activeCount,
      newClientsThisMonth
    };
  }, [orders, clients]);

  // Sidebar jump menu navigators
  const handleMenuJump = (tab: typeof activeTab) => {
    setActiveTab(tab);
    setSideMenuOpen(false);
  };

  // 3D Config ordering handler
  const handleAddOrderFrom3D = (orderData: Partial<Order>) => {
    const fullOrder: Order = {
      id: `ORD-${Math.floor(100 + Math.random() * 900)}`,
      clientName: orderData.clientName || '',
      clientPhone: orderData.clientPhone || '',
      productType: orderData.productType || '3D Жоба (Жиһаз)',
      material: orderData.material || '',
      dimensions: orderData.dimensions || '300x60x240 см',
      price: orderData.price || 0,
      paidAmount: orderData.paidAmount || 0,
      status: 'new',
      createdAt: new Date().toISOString(),
      deliveryDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      notes: orderData.notes,
    };
    addOrder(fullOrder);
  };

  // Fast direct actions from the bottom sheet
  const handleFastAddAction = (productName: string, amount: number) => {
    const fastOrder: Order = {
      id: `ORD-${Math.floor(100 + Math.random() * 900)}`,
      clientName: 'Жылдам Клиент',
      clientPhone: '+7 777 000 1111',
      productType: productName,
      material: 'Қойма маталарынан таңдалады',
      dimensions: 'Стандарт',
      price: amount,
      paidAmount: Math.round(amount * 0.5),
      status: 'new',
      createdAt: new Date().toISOString(),
      deliveryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      notes: 'Кеңседен жылдам тіркелген тапсырыс.',
    };
    addOrder(fastOrder);
    setBottomSheetOpen(false);
    triggerToast('Тапсырыс жылдам қосылды!');
  };

  // Layout selection styling helper
  const appBgStyle = isDarkMode 
    ? "bg-gradient-to-b from-slate-950 via-slate-900 to-sky-950 text-slate-100 selection:bg-sky-500/30 selection:text-sky-200" 
    : "bg-gradient-to-tr from-sky-100 via-sky-50/70 to-blue-200 text-slate-800 selection:bg-sky-200 selection:text-sky-900";

  // Login Screen
  if (!isLoggedIn) {
    return (
      <div className={`min-h-screen flex items-center justify-center p-4 transition-colors duration-500 relative overflow-hidden ${
        isDarkMode 
          ? 'bg-gradient-to-b from-slate-950 via-slate-900 to-sky-950 text-slate-100' 
          : 'bg-gradient-to-tr from-sky-200 via-sky-50 to-blue-200 text-slate-800'
      }`}>
        
        {/* Floating background glowing orbs */}
        <div className="absolute top-[10%] left-[15%] w-[380px] h-[380px] rounded-full bg-sky-400/30 dark:bg-sky-500/15 blur-[120px] animate-float-orb pointer-events-none" />
        <div className="absolute bottom-[10%] right-[10%] w-[440px] h-[440px] rounded-full bg-cyan-400/30 dark:bg-cyan-500/15 blur-[140px] animate-float-orb-reverse pointer-events-none" />
        
        <div className={`w-full max-w-md ${isDarkMode ? 'glass-moldyr-dark bg-slate-900/80 border-slate-800' : 'glass-moldyr-light bg-white/90 border-slate-200/50'} rounded-[36px] p-6 sm:p-8 shadow-2xl relative z-10 transition-all duration-300 transform hover:scale-[1.01]`}>
          
          <div className="flex flex-col items-center text-center space-y-5">
            
            {/* Sofa Brand Logo box */}
            <div className="w-14 h-14 bg-gradient-to-tr from-blue-600 via-indigo-600 to-teal-500 rounded-2xl flex items-center justify-center shadow-lg shadow-indigo-500/20 text-white relative group overflow-hidden">
              <svg viewBox="0 0 64 64" className="w-8 h-8 fill-current">
                <path d="M19 29.5c0-7 5.7-12.7 12.7-12.7H43c3.9 0 7 3.1 7 7v12.4H19v-6.7Z" />
                <path d="M17 35h35c3.3 0 6 2.7 6 6v2.7H11V41c0-3.3 2.7-6 6-6Z" />
                <path d="M18 43.7v10.2M50.5 43.7v10.2M27 43.7l-2.8 10.2M42 43.7l2.8 10.2" />
              </svg>
            </div>

            <div>
              <span className="text-[9px] tracking-[0.2em] text-indigo-600 dark:text-teal-400 font-extrabold uppercase bg-indigo-50 dark:bg-teal-950/40 px-3 py-1 rounded-full border border-indigo-100/50 dark:border-teal-900/30">
                JUMA UI
              </span>
              <h1 className="text-2xl font-black text-slate-900 dark:text-slate-100 mt-2 tracking-tight">Мебель CRM Pro</h1>
              <p className="text-xxs text-slate-500 dark:text-slate-400 mt-1 max-w-xs leading-relaxed">
                Жиһаз өндірісін рөлдерге бөліп басқару жүйесі.
              </p>
            </div>

            {/* Authentication Mode Selector (Login vs Register) */}
            <div className="flex w-full bg-slate-100 dark:bg-slate-950/80 p-1 rounded-2xl border border-slate-200/50 dark:border-slate-800">
              <button 
                onClick={() => { setAuthMode('login'); setLoginError(''); }}
                className={`flex-1 py-2 text-xs font-black rounded-xl transition ${
                  authMode === 'login' 
                    ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-white shadow-sm' 
                    : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
                }`}
              >
                Кіру (Войти)
              </button>
              <button 
                onClick={() => { setAuthMode('register'); setLoginError(''); }}
                className={`flex-1 py-2 text-xs font-black rounded-xl transition ${
                  authMode === 'register' 
                    ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-white shadow-sm' 
                    : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
                }`}
              >
                Тіркелу (Регистрация)
              </button>
            </div>

            {/* Login Method Toggle (Gmail / Phone) */}
            <div className="flex gap-2 w-full justify-center">
              <button
                type="button"
                onClick={() => setLoginMethod('email')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xxs font-bold border transition ${
                  loginMethod === 'email'
                    ? 'bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/30'
                    : 'bg-transparent text-slate-400 border-transparent hover:text-slate-300'
                }`}
              >
                <Monitor className="w-3.5 h-3.5" />
                Gmail / Email
              </button>
              <button
                type="button"
                onClick={() => setLoginMethod('phone')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xxs font-bold border transition ${
                  loginMethod === 'phone'
                    ? 'bg-teal-500/10 text-teal-600 dark:text-teal-400 border-teal-500/30'
                    : 'bg-transparent text-slate-400 border-transparent hover:text-slate-300'
                }`}
              >
                <Smartphone className="w-3.5 h-3.5" />
                Телефон нөмірі
              </button>
            </div>

            {authMode === 'login' ? (
              /* LOGIN FORM */
              <form onSubmit={handleCustomLogin} className="w-full space-y-4">
                {loginMethod === 'email' ? (
                  <div className="space-y-1 text-left">
                    <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Gmail / Email</label>
                    <input 
                      type="email" 
                      placeholder="director@gmail.com немесе өзіңіздікі" 
                      value={loginEmail}
                      onChange={(e) => setLoginEmail(e.target.value)}
                      className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    />
                  </div>
                ) : (
                  <div className="space-y-1 text-left">
                    <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Телефон нөмірі</label>
                    <input 
                      type="text" 
                      placeholder="87771112222" 
                      value={loginPhone}
                      onChange={(e) => setLoginPhone(e.target.value)}
                      className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    />
                  </div>
                )}

                <div className="space-y-1 text-left">
                  <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Құпия сөз (Пароль)</label>
                  <input 
                    type="password" 
                    placeholder="Парольді жазыңыз" 
                    value={loginPassword}
                    onChange={(e) => setLoginPassword(e.target.value)}
                    className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                  />
                </div>

                {loginError && (
                  <p className="text-rose-500 text-xxs font-bold flex items-center justify-center gap-1 bg-rose-500/10 p-2.5 rounded-xl animate-fadeIn">
                    <ShieldAlert className="w-3.5 h-3.5 flex-shrink-0 text-rose-500" />
                    {loginError}
                  </p>
                )}

                <button
                  type="submit"
                  className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 dark:from-teal-500 dark:to-indigo-500 text-white dark:text-slate-950 font-black tracking-wider py-3.5 rounded-2xl shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 active:scale-98 transition duration-200 cursor-pointer text-xs uppercase"
                >
                  Кіру
                </button>
              </form>
            ) : (
              /* REGISTRATION FORM */
              <form onSubmit={handleCustomRegister} className="w-full space-y-4">
                <div className="space-y-1 text-left">
                  <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Толық Аты-жөніңіз</label>
                  <input 
                    type="text" 
                    placeholder="Атыңызды енгізіңіз (мысалы: Дәурен)" 
                    value={registerName}
                    onChange={(e) => setRegisterName(e.target.value)}
                    className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    required
                  />
                </div>

                {/* Role Switcher */}
                <div className="space-y-1 text-left">
                  <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Жүйелік рөл (Роль)</label>
                  <div className="grid grid-cols-2 gap-2 mt-1">
                    <button
                      type="button"
                      onClick={() => setRegisterRole('director')}
                      className={`py-2 px-3 text-xxs font-black border rounded-xl transition ${
                        registerRole === 'director'
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-white/40 dark:bg-slate-950/40 text-slate-400 border-slate-200 dark:border-slate-800 hover:text-slate-200'
                      }`}
                    >
                      Директор (Толық бақылау)
                    </button>
                    <button
                      type="button"
                      onClick={() => setRegisterRole('employee')}
                      className={`py-2 px-3 text-xxs font-black border rounded-xl transition ${
                        registerRole === 'employee'
                          ? 'bg-indigo-600 text-white border-indigo-600'
                          : 'bg-white/40 dark:bg-slate-950/40 text-slate-400 border-slate-200 dark:border-slate-800 hover:text-slate-200'
                      }`}
                    >
                      Қызметкер (Шектеулі рұқсат)
                    </button>
                  </div>
                </div>

                {loginMethod === 'email' ? (
                  <div className="space-y-1 text-left">
                    <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Gmail / Email мекен-жайы</label>
                    <input 
                      type="email" 
                      placeholder="mysal@gmail.com" 
                      value={registerEmail}
                      onChange={(e) => setRegisterEmail(e.target.value)}
                      className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    />
                  </div>
                ) : (
                  <div className="space-y-1 text-left">
                    <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Телефон нөмірі</label>
                    <input 
                      type="text" 
                      placeholder="87779998888" 
                      value={registerPhone}
                      onChange={(e) => setRegisterPhone(e.target.value)}
                      className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    />
                  </div>
                )}

                <div className="space-y-1 text-left">
                  <label className="text-3xs uppercase tracking-wider font-extrabold text-slate-400">Құпия сөз таңдаңыз (Пароль)</label>
                  <input 
                    type="password" 
                    placeholder="Ең кемі 4 таңба" 
                    value={registerPassword}
                    onChange={(e) => setRegisterPassword(e.target.value)}
                    className="w-full bg-white/60 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 focus:border-indigo-500 transition-all"
                    required
                  />
                </div>

                {loginError && (
                  <p className="text-rose-500 text-xxs font-bold flex items-center justify-center gap-1 bg-rose-500/10 p-2.5 rounded-xl animate-fadeIn">
                    <ShieldAlert className="w-3.5 h-3.5 flex-shrink-0 text-rose-500" />
                    {loginError}
                  </p>
                )}

                <button
                  type="submit"
                  className="w-full bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-black tracking-wider py-3.5 rounded-2xl shadow-lg shadow-teal-500/10 hover:shadow-teal-500/20 active:scale-98 transition duration-200 cursor-pointer text-xs uppercase"
                >
                  Жаңа аккаунт тіркеу
                </button>
              </form>
            )}

            {/* Test credentials helper - COLLAPSIBLE COMPACT BAR */}
            <div className="w-full bg-slate-500/5 dark:bg-slate-800/40 rounded-2xl p-3 border border-slate-200/40 dark:border-slate-800/40 text-left">
              <p className="text-[8px] uppercase tracking-widest font-black text-slate-400 dark:text-slate-500 flex justify-between">
                <span>Сынақ аккаунттар (Жылдам тексеру):</span>
                <span className="text-indigo-400 animate-pulse font-bold">БҰЛТҚА ҚОСЫЛҒАН ☁️</span>
              </p>
              
              <div className="mt-2 grid grid-cols-2 gap-2 text-3xs border-t border-dashed border-slate-200/20 pt-2 text-slate-500 dark:text-slate-400 font-mono">
                <div>
                  <span className="font-sans font-bold text-blue-500 block">Директор (Gmail)</span>
                  <p>Email: <strong className="text-slate-300">director@gmail.com</strong></p>
                  <p>Пароль: <strong className="text-slate-300">2606</strong></p>
                </div>
                <div>
                  <span className="font-sans font-bold text-teal-500 block">Директор (Телефон)</span>
                  <p>Тел: <strong className="text-slate-300">87771112222</strong></p>
                  <p>Пароль: <strong className="text-slate-300">2606</strong></p>
                </div>
                <div className="border-t border-slate-200/10 pt-1.5 mt-1">
                  <span className="font-sans font-bold text-indigo-400 block">Қызметкер (Gmail)</span>
                  <p>Email: <strong className="text-slate-300">employee@gmail.com</strong></p>
                  <p>Пароль: <strong className="text-slate-300">1111</strong></p>
                </div>
                <div className="border-t border-slate-200/10 pt-1.5 mt-1">
                  <span className="font-sans font-bold text-amber-500 block">Қызметкер (Телефон)</span>
                  <p>Тел: <strong className="text-slate-300">87773334444</strong></p>
                  <p>Пароль: <strong className="text-slate-300">1111</strong></p>
                </div>
              </div>
            </div>

          </div>

        </div>
      </div>
    );
  }

  // Active workspace once logged in
  // Dedicated native Telegram Mini App / Mobile viewport layout
  if (isMobileViewport) {
    return (
      <div className={`min-h-screen ${isDarkMode ? 'bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'} flex flex-col justify-between relative overflow-hidden transition-colors duration-300`}>
        {/* GLOWING AURORA BACKGROUNDS */}
        <div className="absolute top-10 left-[-50px] w-48 h-48 bg-teal-500/10 rounded-full blur-[40px] pointer-events-none" />
        <div className="absolute bottom-10 right-[-50px] w-48 h-48 bg-indigo-500/10 rounded-full blur-[40px] pointer-events-none" />

        {/* STICKY TELEGRAM STYLE HEADER */}
        <div className={`px-4 py-3.5 flex justify-between items-center border-b ${isDarkMode ? 'border-slate-800/60 bg-slate-950/80' : 'border-slate-200/60 bg-white/85'} backdrop-blur-md sticky top-0 z-40 transition-colors`}>
          <button 
            onClick={() => setSideMenuOpen(!sideMenuOpen)}
            className={`p-2 rounded-xl border transition ${
              isDarkMode 
                ? 'bg-slate-800/80 border-slate-700/50 hover:bg-slate-700/80 text-slate-200' 
                : 'bg-slate-100 border-slate-200 hover:bg-slate-200 text-slate-800'
            } cursor-pointer`}
          >
            <Menu className="w-4 h-4" />
          </button>
          
          <div className="text-center">
            <p className="text-[9px] font-black tracking-[0.2em] text-blue-500 dark:text-teal-400">JUMA UI</p>
            <h4 className={`text-sm font-black ${isDarkMode ? 'text-white' : 'text-slate-900'} capitalize mt-0.5`}>
              {activeTab === 'home' ? 'Басты бет' : 
               activeTab === 'orders' ? 'Тапсырыстар' :
               activeTab === 'clients' ? 'Клиенттер' :
               activeTab === 'inventory' ? 'Қойма қалдығы' :
               activeTab === 'reports' ? 'Есеп аналитикасы' :
               activeTab === 'employees' ? 'Бонустар' :
               activeTab === 'measurements' ? 'Өлшеу кестесі' : '3D Модельдеу'}
            </h4>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setIsDarkMode(!isDarkMode)}
              className={`p-2 rounded-xl border transition ${
                isDarkMode 
                  ? 'bg-slate-800/80 border-slate-700/50 text-slate-200' 
                  : 'bg-slate-100 border-slate-200 text-slate-800'
              } cursor-pointer`}
            >
              {isDarkMode ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
            <button 
              onClick={() => {
                setBottomSheetType('notifications');
                setBottomSheetOpen(true);
              }}
              className={`p-2 rounded-xl border transition relative ${
                isDarkMode 
                  ? 'bg-slate-800/80 border-slate-700/50 text-slate-200' 
                  : 'bg-slate-100 border-slate-200 text-slate-800'
              } cursor-pointer`}
            >
              <Bell className="w-4 h-4" />
              <span className="absolute top-1 right-1 w-1.5 h-1.5 rounded-full bg-blue-500 animate-ping" />
            </button>
          </div>
        </div>

        {/* SCROLLABLE INTERACTIVE VIEW CONTENT */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 pb-28">
          {activeTab === 'home' ? (
            <div className="space-y-4 animate-fadeIn">
              
              {/* Welcome Card styled beautifully */}
              <div className="bg-gradient-to-r from-blue-600 via-indigo-600 to-indigo-700 text-white rounded-3xl p-5 shadow-lg shadow-indigo-600/15 relative overflow-hidden">
                <div className="absolute right-[-20px] top-[-20px] w-32 h-32 bg-white/10 rounded-full blur-xl pointer-events-none" />
                <div className="absolute left-[-20px] bottom-[-20px] w-24 h-24 bg-white/5 rounded-full blur-lg pointer-events-none" />
                
                <div className="flex gap-4 items-center relative z-10">
                  <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white shadow-inner">
                    <Layout className="w-6 h-6 animate-pulse" />
                  </div>
                  <div>
                    <p className="text-[10px] text-white/70 font-semibold uppercase tracking-widest">Сәлеметсіз бе,</p>
                    <h3 className="text-lg font-black tracking-tight mt-0.5">{currentUser?.name || 'Қолданушы'}</h3>
                    <span className="text-[10px] bg-emerald-500/30 text-emerald-200 px-2.5 py-0.5 rounded-full font-medium inline-block mt-1">
                      {currentUser?.role === 'director' ? 'Директор (Толық бақылау)' : 'Қызметкер (Шектеулі рұқсат)'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Dynamic counters based on role */}
              <div className="grid grid-cols-2 gap-2.5">
                {currentUser?.role === 'director' ? (
                  <>
                    <div className={`border p-3.5 rounded-2xl shadow-sm ${isDarkMode ? 'bg-slate-800/40 border-slate-200/10' : 'bg-white border-slate-100'}`}>
                      <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Жалпы айналым</p>
                      <h4 className="text-sm font-black text-blue-500 dark:text-blue-400 font-mono mt-1">{financialStats.totalRevenue.toLocaleString()} ₸</h4>
                    </div>
                    <div className={`border p-3.5 rounded-2xl shadow-sm ${isDarkMode ? 'bg-slate-800/40 border-slate-200/10' : 'bg-white border-slate-100'}`}>
                      <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Нақты касса</p>
                      <h4 className="text-sm font-black text-emerald-500 dark:text-emerald-400 font-mono mt-1">{financialStats.totalPaid.toLocaleString()} ₸</h4>
                    </div>
                  </>
                ) : (
                  <>
                    <div className={`border p-3.5 rounded-2xl shadow-sm ${isDarkMode ? 'bg-slate-800/40 border-slate-200/10' : 'bg-white border-slate-100'}`}>
                      <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Жалпы Тапсырыстар</p>
                      <h4 className="text-sm font-black text-indigo-500 dark:text-indigo-400 font-mono mt-1">{orders.length} дана</h4>
                    </div>
                    <div className={`border p-3.5 rounded-2xl shadow-sm ${isDarkMode ? 'bg-slate-800/40 border-slate-200/10' : 'bg-white border-slate-100'}`}>
                      <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Белсенді Тапсырыстар</p>
                      <h4 className="text-sm font-black text-amber-500 dark:text-amber-400 font-mono mt-1">{financialStats.activeCount} дана</h4>
                    </div>
                  </>
                )}
              </div>

              {/* Bento Grid modules jump links */}
              <div>
                <div className="flex justify-between items-center mb-2.5">
                  <h4 className={`text-[10px] font-extrabold ${isDarkMode ? 'text-slate-400' : 'text-slate-500'} uppercase tracking-widest`}>Негізгі модульдер</h4>
                  <span className="text-[8px] font-bold text-blue-500 uppercase">Оңтайландырылған</span>
                </div>
                <div className="grid grid-cols-3 gap-2.5">
                  {[
                    { id: 'orders', label: 'Тапсырыс', icon: Package, color: 'text-blue-500 bg-blue-500/10 border-blue-500/20' },
                    { id: 'clients', label: 'Клиенттер', icon: Users, color: 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20' },
                    { id: '3d', label: 'Өнімдер', icon: Sparkles, color: 'text-purple-500 bg-purple-500/10 border-purple-500/20' },
                    { id: 'inventory', label: 'Қойма', icon: Package, color: 'text-amber-500 bg-amber-500/10 border-amber-500/20' },
                    { id: 'reports', label: 'Есептер', icon: BarChart3, color: 'text-cyan-500 bg-cyan-500/10 border-cyan-500/20' },
                    { id: 'employees', label: 'Бонустар', icon: Users2, color: 'text-rose-500 bg-rose-500/10 border-rose-500/20' },
                  ].filter(item => {
                    if (currentUser?.role === 'employee') {
                      return item.id !== 'reports' && item.id !== 'employees';
                    }
                    return true;
                  }).map(item => (
                    <button
                      key={item.id}
                      onClick={() => setActiveTab(item.id as typeof activeTab)}
                      className={`border rounded-2xl p-3 flex flex-col items-center text-center gap-2 cursor-pointer transition-all duration-200 hover:-translate-y-1 active:scale-95 shadow-sm ${
                        isDarkMode 
                          ? 'bg-slate-800/40 border-slate-800/60' 
                          : 'bg-white border-slate-100 hover:bg-slate-50'
                      }`}
                    >
                      <div className={`p-2 rounded-xl ${item.color} border flex items-center justify-center`}>
                        <item.icon className="w-4 h-4" />
                      </div>
                      <span className={`text-[9px] font-black tracking-tight ${isDarkMode ? 'text-slate-200' : 'text-slate-700'}`}>{item.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Promo Sofa 3D Design card */}
              <button 
                onClick={() => setActiveTab('3d')}
                className="w-full bg-gradient-to-r from-blue-500/15 to-indigo-500/15 hover:from-blue-500/20 hover:to-indigo-500/20 border border-blue-500/30 rounded-2xl p-4 text-left relative overflow-hidden transition cursor-pointer group"
              >
                <div className="absolute right-[-15px] bottom-[-15px] opacity-15 group-hover:scale-110 transition-transform">
                  <Layout className="w-24 h-24 text-blue-500" />
                </div>
                <span className="px-2 py-0.5 bg-blue-500/20 border border-blue-500/30 rounded text-[8px] font-bold text-blue-400 uppercase tracking-wider">
                  Интерактивті
                </span>
                <h4 className={`text-xs font-black ${isDarkMode ? 'text-white' : 'text-slate-850'} mt-1.5`}>3D Жиһаз Конструкторы</h4>
                <p className="text-[9px] text-slate-400 mt-1 max-w-[210px] leading-normal">
                  Материал, фурнитура және өлшемін таңдап, бұйым құнын бірден есептеңіз!
                </p>
              </button>

              {/* Recent Orders List summary inside Home */}
              <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-slate-800/20 border-slate-800/80' : 'bg-white border-slate-100'}`}>
                <div className="flex justify-between items-center mb-3">
                  <h4 className={`text-[10px] font-black uppercase tracking-wider ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>Соңғы тапсырыстар</h4>
                  <button onClick={() => setActiveTab('orders')} className="text-[9px] font-bold text-blue-500 hover:underline">Барлығын көру</button>
                </div>
                <div className="space-y-2">
                  {orders.slice(0, 3).map(o => (
                    <div 
                      key={o.id} 
                      onClick={() => {
                        setSelectedOrderDetail(o);
                        setBottomSheetType('order_detail');
                        setBottomSheetOpen(true);
                      }}
                      className={`p-3 rounded-xl border flex justify-between items-center cursor-pointer transition ${
                        isDarkMode 
                          ? 'bg-slate-900/60 border-slate-800/60 hover:bg-slate-800/40' 
                          : 'bg-slate-50 border-slate-100 hover:bg-slate-100/60'
                      }`}
                    >
                      <div>
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] font-black font-mono text-blue-500">{o.id}</span>
                          <span className="text-[8px] px-1.5 py-0.2 bg-blue-500/15 text-blue-400 rounded-full font-bold uppercase">{STATUS_KAZAKH[o.status]}</span>
                        </div>
                        <h5 className={`text-xs font-bold ${isDarkMode ? 'text-white' : 'text-slate-800'} mt-0.5`}>{o.clientName}</h5>
                        <p className="text-[9px] text-slate-400">{o.productType}</p>
                      </div>
                      <span className={`text-xs font-black font-mono ${isDarkMode ? 'text-white' : 'text-slate-900'}`}>{o.price.toLocaleString()} ₸</span>
                    </div>
                  ))}
                </div>
              </div>

            </div>
          ) : activeTab === 'orders' ? (
            <div className="animate-fadeIn">
              <OrdersModule 
                orders={orders} 
                employees={employees} 
                onAddOrder={addOrder} 
                onUpdateOrder={updateOrder} 
                onDeleteOrder={deleteOrder} 
                onShowToast={triggerToast} 
                showAddFormProp={showAddOrderForm}
                onShowAddFormChange={setShowAddOrderForm}
              />
            </div>
          ) : activeTab === 'clients' ? (
            <div className="animate-fadeIn">
              <ClientsModule 
                clients={clients} 
                orders={orders}
                onAddClient={addClient} 
                onShowToast={triggerToast} 
              />
            </div>
          ) : activeTab === 'inventory' ? (
            <div className="animate-fadeIn">
              <InventoryModule 
                inventory={inventory} 
                onUpdateInventory={updateInventory} 
                onShowToast={triggerToast} 
              />
            </div>
          ) : activeTab === 'reports' ? (
            <div className="animate-fadeIn">
              <ReportsModule 
                orders={orders} 
                clients={clients} 
                inventory={inventory}
              />
            </div>
          ) : activeTab === 'employees' ? (
            <div className="animate-fadeIn">
              <EmployeesModule 
                employees={employees} 
                onRewardBonus={rewardEmployeeBonus} 
                onShowToast={triggerToast} 
              />
            </div>
          ) : activeTab === 'measurements' ? (
            <div className="animate-fadeIn">
              <MeasurementsModule 
                measurements={measurements} 
                onAddMeasurement={addMeasurement} 
                onUpdateMeasurement={updateMeasurement} 
                onShowToast={triggerToast} 
              />
            </div>
          ) : (
            <div className="animate-fadeIn">
              <Visualizer3D 
                onAddOrderFromConfig={handleAddOrderFrom3D} 
                onShowToast={triggerToast} 
              />
            </div>
          )}
        </div>

        {/* BOTTOM ACTION NAVIGATION BAR PINNED */}
        <div className={`fixed bottom-0 left-0 right-0 p-3 pb-safe z-40 border-t ${
          isDarkMode ? 'bg-slate-950/95 border-slate-900' : 'bg-white/95 border-slate-200/60'
        } backdrop-blur-md`}>
          <nav className="max-w-md mx-auto flex justify-between items-center relative select-none px-4">
            
            <button 
              onClick={() => setActiveTab('home')}
              className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                activeTab === 'home' 
                  ? 'text-blue-500 scale-105 font-bold' 
                  : `${isDarkMode ? 'text-slate-500 hover:text-slate-300' : 'text-slate-400 hover:text-slate-600'}`
              }`}
            >
              <div className={`p-1.5 rounded-xl transition ${activeTab === 'home' ? 'bg-blue-500/10' : ''}`}>
                <Layout className="w-5 h-5" />
              </div>
              <span className="text-[8px] font-bold">Басты бет</span>
            </button>

            <button 
              onClick={() => setActiveTab('orders')}
              className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                activeTab === 'orders' 
                  ? 'text-blue-500 scale-105 font-bold' 
                  : `${isDarkMode ? 'text-slate-500 hover:text-slate-300' : 'text-slate-400 hover:text-slate-600'}`
              }`}
            >
              <div className={`p-1.5 rounded-xl transition ${activeTab === 'orders' ? 'bg-blue-500/10' : ''}`}>
                <Package className="w-5 h-5" />
              </div>
              <span className="text-[8px] font-bold">Тапсырыс</span>
            </button>

            {/* Middle FAB */}
            <button 
              onClick={() => {
                setActiveTab('orders');
                setShowAddOrderForm(true);
              }}
              className="w-12 h-12 bg-gradient-to-r from-blue-600 to-indigo-600 hover:scale-105 active:scale-95 text-white rounded-full flex items-center justify-center shadow-lg shadow-indigo-500/30 cursor-pointer z-50 transform -translate-y-4 transition-all"
            >
              <Plus className="w-6 h-6 font-black" />
            </button>

            <button 
              onClick={() => setActiveTab('inventory')}
              className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                activeTab === 'inventory' 
                  ? 'text-blue-500 scale-105 font-bold' 
                  : `${isDarkMode ? 'text-slate-500 hover:text-slate-300' : 'text-slate-400 hover:text-slate-600'}`
              }`}
            >
              <div className={`p-1.5 rounded-xl transition ${activeTab === 'inventory' ? 'bg-blue-500/10' : ''}`}>
                <Users className="w-5 h-5" />
              </div>
              <span className="text-[8px] font-bold">Қойма</span>
            </button>

            <button 
              onClick={() => setActiveTab('3d')}
              className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                activeTab === '3d' 
                  ? 'text-blue-500 scale-105 font-bold' 
                  : `${isDarkMode ? 'text-slate-500 hover:text-slate-300' : 'text-slate-400 hover:text-slate-600'}`
              }`}
            >
              <div className={`p-1.5 rounded-xl transition ${activeTab === '3d' ? 'bg-blue-500/10' : ''}`}>
                <Compass className="w-5 h-5" />
              </div>
              <span className="text-[8px] font-bold">3D модель</span>
            </button>

          </nav>
        </div>

        {/* MOBILE SLIDING DRAWER MENU */}
        {sideMenuOpen && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity flex items-end">
            <div className={`w-full ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-100'} border-t rounded-t-[32px] p-6 space-y-4 max-h-[85vh] overflow-y-auto animate-slideUp`}>
              <div className="w-12 h-1.5 bg-slate-400 dark:bg-slate-700 rounded-full mx-auto cursor-pointer" onClick={() => setSideMenuOpen(false)} />
              <div className="flex justify-between items-center">
                <h3 className="font-black text-sm text-blue-500 dark:text-teal-400 uppercase tracking-widest">JUMA UI Мәзірі</h3>
                <span className="text-[9px] font-mono opacity-60">CRM v2.0</span>
              </div>
              
              <div className="grid grid-cols-1 gap-2 text-xs">
                {[
                  { id: 'orders', label: 'Тапсырыстарды бақылау', desc: 'Өндіріс кезеңдерін бақылау' },
                  { id: 'clients', label: 'Клиенттер базасы', desc: 'Сатып алушылар мен LTV талдау' },
                  { id: 'measurements', label: 'Замер базасы (Өлшем кестесі)', desc: 'Маманның бару жоспары' },
                  { id: 'employees', label: 'Бонус және Қызметкерлер', desc: 'Еңбекақы мен жасалған жұмыс' },
                  { id: 'inventory', label: 'Қойма қалдықтары', desc: 'Поролон, ағаш және мата қалдығы' },
                  { id: 'reports', label: 'Есеп аналитикасы', desc: 'Таза пайда және касса көрсеткіштері' },
                ].filter(item => {
                  if (currentUser?.role === 'employee') {
                    return item.id !== 'reports' && item.id !== 'employees';
                  }
                  return true;
                }).map(item => (
                  <button 
                    key={item.id}
                    onClick={() => handleMenuJump(item.id as typeof activeTab)} 
                    className={`w-full text-left p-3.5 rounded-2xl border transition flex flex-col gap-0.5 cursor-pointer ${
                      isDarkMode 
                        ? 'bg-slate-800/80 border-slate-700/40 hover:bg-slate-700/80 text-white' 
                        : 'bg-slate-50 border-slate-200 hover:bg-slate-100 text-slate-800'
                    }`}
                  >
                    <span className="font-bold text-xs">{item.label}</span>
                    <span className="text-[9px] text-slate-400">{item.desc}</span>
                  </button>
                ))}
              </div>

              <button 
                onClick={() => setSideMenuOpen(false)}
                className={`w-full py-3.5 rounded-2xl text-xs font-black transition cursor-pointer ${
                  isDarkMode ? 'bg-slate-800 hover:bg-slate-700 text-slate-200' : 'bg-slate-100 hover:bg-slate-200 text-slate-800'
                }`}
              >
                Жабу
              </button>
            </div>
          </div>
        )}

        {/* MOBILE BOTTOM SHEET DRAWER */}
        {bottomSheetOpen && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity flex items-end">
            <div className={`w-full ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-100'} border-t rounded-t-[32px] p-6 space-y-4 max-h-[85vh] overflow-y-auto animate-slideUp`}>
              
              <div className="w-12 h-1.5 bg-slate-400 dark:bg-slate-700 rounded-full mx-auto cursor-pointer" onClick={() => setBottomSheetOpen(false)} />

              {bottomSheetType === 'add_fast' && (
                <div className="space-y-4">
                  <div className="space-y-1">
                    <span className="text-[10px] font-black tracking-widest text-blue-500 dark:text-teal-400 uppercase">Жаңа әрекет</span>
                    <h3 className={`font-black text-base ${isDarkMode ? 'text-white' : 'text-slate-900'}`}>Жылдам Тапсырыс Қосу</h3>
                    <p className="text-[10px] text-slate-400">Таңдалған жиһаз үлгісін бірден тіркеңіз (50% алдын ала төлеммен):</p>
                  </div>

                  <div className="space-y-2 text-xs">
                    {[
                      { name: 'Ас үй гарнитуры (MDF)', price: 850000, desc: 'Боялған МДФ фасадтар, Blum баяу жапқыштар' },
                      { name: 'Шкаф-купе Премиум', price: 480000, desc: 'Egger ЛДСП корпусы, толық айналы есіктер' },
                      { name: 'ТВ консоль / Комод', price: 120000, desc: 'Талғампаз қонақ бөлме қысқа комоды' }
                    ].map(prod => (
                      <button 
                        key={prod.name}
                        onClick={() => handleFastAddAction(prod.name, prod.price)} 
                        className={`w-full flex justify-between items-center p-3.5 rounded-2xl border transition cursor-pointer ${
                          isDarkMode 
                            ? 'bg-slate-800/80 border-slate-700/40 hover:bg-slate-700/80 text-white' 
                            : 'bg-slate-50 border-slate-200 hover:bg-slate-100 text-slate-800'
                        }`}
                      >
                        <div className="text-left">
                          <p className="font-bold text-xs">{prod.name}</p>
                          <span className="text-[9px] text-slate-400">{prod.desc}</span>
                        </div>
                        <strong className="text-blue-500 dark:text-teal-400 font-mono text-sm">{(prod.price / 1000)}К ₸</strong>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {bottomSheetType === 'notifications' && (
                <div className="space-y-4">
                  <h3 className={`font-black text-sm uppercase tracking-widest ${isDarkMode ? 'text-white' : 'text-slate-900'}`}>Қызметтік хабарламалар</h3>
                  <div className="space-y-2.5">
                    <div className={`p-3.5 rounded-2xl border-l-4 border-blue-500 ${isDarkMode ? 'bg-slate-800/40' : 'bg-slate-50'}`}>
                      <p className={`font-bold text-xs ${isDarkMode ? 'text-white' : 'text-slate-850'}`}>Жаңа тапсырыс сәтті құрылды</p>
                      <p className="text-[10px] text-slate-400 mt-0.5">3D Диван Конструкторынан жаңа өтінім тіркелді.</p>
                      <span className="text-slate-400 text-[8px] block mt-1">10 минут бұрын</span>
                    </div>
                    <div className={`p-3.5 rounded-2xl border-l-4 border-amber-500 ${isDarkMode ? 'bg-slate-800/40' : 'bg-slate-50'}`}>
                      <p className={`font-bold text-xs ${isDarkMode ? 'text-white' : 'text-slate-850'}`}>Қоймада мата қалдығы аз!</p>
                      <p className="text-[10px] text-slate-400 mt-0.5">«Royal Velvet» жасыл матасының қалдығы 15 метрден аспайды.</p>
                      <span className="text-slate-400 text-[8px] block mt-1">2 сағат бұрын</span>
                    </div>
                  </div>
                </div>
              )}

              {bottomSheetType === 'order_detail' && selectedOrderDetail && (
                <div className="space-y-4 text-left">
                  <div className="flex justify-between items-start border-b pb-3 border-slate-200/10 dark:border-slate-800">
                    <div>
                      <span className="text-[9px] font-black tracking-widest text-blue-500 dark:text-teal-400 uppercase">Тапсырыс мәліметі</span>
                      <h3 className={`font-black text-base ${isDarkMode ? 'text-white' : 'text-slate-900'} mt-0.5`}>{selectedOrderDetail.id}</h3>
                    </div>
                    <span className="px-2.5 py-0.5 rounded-full bg-blue-500/15 text-blue-500 dark:text-blue-400 text-[10px] font-black uppercase">
                      {STATUS_KAZAKH[selectedOrderDetail.status]}
                    </span>
                  </div>

                  <div className="space-y-2 text-xs">
                    <div className="flex justify-between">
                      <span className="text-slate-400">Клиент:</span>
                      <strong className={isDarkMode ? 'text-white' : 'text-slate-800'}>{selectedOrderDetail.clientName}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Телефон:</span>
                      <strong className={isDarkMode ? 'text-white font-mono' : 'text-slate-800 font-mono'}>{selectedOrderDetail.clientPhone}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Бұйым:</span>
                      <strong className={isDarkMode ? 'text-white' : 'text-slate-800'}>{selectedOrderDetail.productType}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Жалпы құны:</span>
                      <strong className="text-blue-500 dark:text-teal-400 font-mono font-bold text-sm">{selectedOrderDetail.price.toLocaleString()} ₸</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Төленгені (Касса):</span>
                      <strong className="text-emerald-500 font-mono font-bold">{selectedOrderDetail.paidAmount.toLocaleString()} ₸</strong>
                    </div>
                    {selectedOrderDetail.notes && (
                      <div className="pt-2 border-t border-slate-200/10 dark:border-slate-800">
                        <span className="text-slate-400 block mb-1">Қосымша жазбалар:</span>
                        <p className={`p-2.5 rounded-xl text-[10px] italic leading-relaxed ${isDarkMode ? 'bg-slate-800/40 text-slate-300' : 'bg-slate-50 text-slate-600'}`}>{selectedOrderDetail.notes}</p>
                      </div>
                    )}
                  </div>

                  {/* HIGH-END INTERACTIVE TIMELINE / STEPPER STATUS TRACKER */}
                  <div className="pt-4 border-t border-slate-200/10 dark:border-slate-800">
                    <h4 className={`text-[10px] font-black uppercase tracking-wider ${isDarkMode ? 'text-slate-400' : 'text-slate-500'} mb-3`}>Өндіріс кезеңдерінің барысы</h4>
                    
                    <div className="relative pl-6 space-y-4">
                      {/* Vertical line connector */}
                      <div className="absolute top-1 left-2 w-0.5 bg-slate-200 dark:bg-slate-800 h-[85%] z-0" />

                      {[
                        { status: 'new', label: 'Жаңа өтінім', desc: 'Тапсырыс тіркелді, алдын ала төлем қабылданды' },
                        { status: 'measurement', label: 'Замер/Өлшеу', desc: 'Өлшемдер нақтыланып, сызба бекітілді' },
                        { status: 'production', label: 'Өндірісте (Цехта)', desc: 'Каркас жиналып, поролон мен мата тартылуда' },
                        { status: 'delivery', label: 'Жеткізуде', desc: 'Жиһаз клиент мекен-жайына жіберілді' },
                        { status: 'completed', label: 'Тапсырыс аяқталды', desc: 'Орнатылып, толық есеп айырысу жасалды' }
                      ].map((step) => {
                        const isPast = ['new', 'measurement', 'production', 'delivery', 'completed'].indexOf(selectedOrderDetail.status) >= ['new', 'measurement', 'production', 'delivery', 'completed'].indexOf(step.status);
                        const isActive = selectedOrderDetail.status === step.status;

                        return (
                          <div key={step.status} className="relative z-10">
                            {/* Circle Indicator */}
                            <div className={`absolute left-[-22px] top-1 w-3.5 h-3.5 rounded-full border-2 transition-all ${
                              isActive 
                                ? 'bg-blue-500 border-blue-500 scale-125 ring-4 ring-blue-500/20' 
                                : isPast 
                                  ? 'bg-blue-500 border-blue-500' 
                                  : 'bg-slate-900 border-slate-700 dark:bg-slate-950'
                            }`} />
                            
                            <div>
                              <h5 className={`text-xs font-bold transition-colors ${
                                isActive ? 'text-blue-500 dark:text-blue-400' : isPast ? 'text-slate-300 dark:text-slate-200' : 'text-slate-500'
                              }`}>{step.label}</h5>
                              <p className="text-[9px] text-slate-400 mt-0.5">{step.desc}</p>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* QUICK STATUS TRANSITION BUTTONS */}
                  <div className="pt-4 flex gap-2">
                    {selectedOrderDetail.status !== 'completed' && selectedOrderDetail.status !== 'cancelled' && (
                      <button
                        onClick={() => {
                          const statusOrder = ['new', 'measurement', 'production', 'delivery', 'completed'] as OrderStatus[];
                          const currentIdx = statusOrder.indexOf(selectedOrderDetail.status);
                          if (currentIdx !== -1 && currentIdx < statusOrder.length - 1) {
                            const nextStatus = statusOrder[currentIdx + 1];
                            updateOrder({ ...selectedOrderDetail, status: nextStatus });
                            setSelectedOrderDetail({ ...selectedOrderDetail, status: nextStatus });
                          }
                        }}
                        className="flex-1 bg-blue-600 hover:bg-blue-500 text-white py-3 rounded-2xl text-xs font-black transition cursor-pointer shadow-lg shadow-blue-500/10 flex items-center justify-center gap-1"
                      >
                        Келесі кезең <ArrowRight className="w-3.5 h-3.5" />
                      </button>
                    )}
                    <button
                      onClick={() => setBottomSheetOpen(false)}
                      className={`px-5 py-3 rounded-2xl text-xs font-bold transition cursor-pointer ${
                        isDarkMode ? 'bg-slate-800 hover:bg-slate-700 text-slate-200' : 'bg-slate-100 hover:bg-slate-200 text-slate-800'
                      }`}
                    >
                      Жабу
                    </button>
                  </div>
                </div>
              )}

              <button 
                onClick={() => setBottomSheetOpen(false)}
                className={`w-full py-3.5 rounded-2xl text-xs font-black transition cursor-pointer ${
                  isDarkMode ? 'bg-slate-800 hover:bg-slate-700 text-slate-300' : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                Жабу
              </button>
            </div>
          </div>
        )}

        {/* SYSTEM TOAST ALERTS */}
        {toastMessage && (
          <div className="fixed bottom-24 left-4 right-4 z-[99] flex justify-center animate-fadeIn">
            <div className="bg-slate-900/90 text-white border border-slate-700/50 backdrop-blur-md px-5 py-3 rounded-2xl text-xs font-bold shadow-2xl flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-blue-400 animate-spin" style={{ animationDuration: '3s' }} />
              {toastMessage}
            </div>
          </div>
        )}

      </div>
    );
  }

  // Active workspace once logged in
  return (
    <div className={`min-h-screen ${appBgStyle} transition-colors duration-300 relative pb-16 lg:pb-0 overflow-x-hidden`}>
      
      {/* GLOWING CRYSTALLINE AURORA BACKGROUNDS */}
      <div className="absolute top-[-5%] right-[-10%] w-[600px] h-[600px] bg-sky-400/20 dark:bg-sky-500/10 rounded-full blur-[130px] animate-float-orb pointer-events-none" />
      <div className="absolute bottom-[-5%] left-[-10%] w-[600px] h-[600px] bg-cyan-400/20 dark:bg-cyan-500/10 rounded-full blur-[130px] animate-float-orb-reverse pointer-events-none" />
      <div className="absolute top-[30%] left-[20%] w-[400px] h-[400px] bg-blue-400/15 dark:bg-blue-500/5 rounded-full blur-[120px] animate-pulse pointer-events-none" style={{ animationDuration: '10s' }} />

      {/* WORKSPACE TOP MAIN HEADER */}
      <header className={`border-b sticky top-0 z-40 px-6 py-4 flex justify-between items-center transition-all ${
        isDarkMode 
          ? 'glass-moldyr-dark bg-slate-950/40 border-sky-500/10' 
          : 'glass-moldyr-light bg-sky-50/40 border-white/40'
      }`}>
        
        {/* Brand Label */}
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-teal-600 dark:bg-teal-500 rounded-lg flex items-center justify-center text-white shadow-sm">
            <svg viewBox="0 0 64 64" className="w-6 h-6 fill-current">
              <path d="M19 29.5c0-7 5.7-12.7 12.7-12.7H43c3.9 0 7 3.1 7 7v12.4H19v-6.7Z" />
              <path d="M17 35h35c3.3 0 6 2.7 6 6v2.7H11V41c0-3.3 2.7-6 6-6Z" />
              <path d="M18 43.7v10.2M50.5 43.7v10.2M27 43.7l-2.8 10.2M42 43.7l2.8 10.2" />
            </svg>
          </div>
          <div>
            <span className="text-slate-900 dark:text-white font-black text-sm tracking-tight">JUMA UI</span>
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-teal-500 animate-pulse" />
              <span className="text-4xs uppercase tracking-widest font-black text-slate-400 dark:text-slate-500">Мебель CRM Pro</span>
            </div>
          </div>
        </div>

        {/* View Layout Selection (Mobile Phone Mockup vs Full Desktop vs Dual Split) */}
        <div className="hidden lg:flex bg-slate-100 dark:bg-slate-800 border border-slate-200/50 dark:border-slate-700/60 p-1 rounded-xl gap-1">
          <button
            onClick={() => setViewLayout('split')}
            className={`px-3 py-1.5 rounded-lg text-xxs font-bold flex items-center gap-1 cursor-pointer transition ${
              viewLayout === 'split' ? 'bg-white dark:bg-slate-700 text-teal-600 dark:text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <Monitor className="w-3.5 h-3.5" />
            Компьютер + Телефон
          </button>
          <button
            onClick={() => setViewLayout('desktop-only')}
            className={`px-3 py-1.5 rounded-lg text-xxs font-bold flex items-center gap-1 cursor-pointer transition ${
              viewLayout === 'desktop-only' ? 'bg-white dark:bg-slate-700 text-teal-600 dark:text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <Monitor className="w-3.5 h-3.5" />
            Тек Компьютер
          </button>
          <button
            onClick={() => setViewLayout('phone-only')}
            className={`px-3 py-1.5 rounded-lg text-xxs font-bold flex items-center gap-1 cursor-pointer transition ${
              viewLayout === 'phone-only' ? 'bg-white dark:bg-slate-700 text-teal-600 dark:text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            Тек Телефон
          </button>
        </div>

        {/* Header Right controllers */}
        <div className="flex items-center gap-2">
          
          {/* Cloud Sync Status Indicator */}
          <div className="flex items-center gap-1.5 bg-slate-100/80 dark:bg-slate-800/85 border border-slate-200/50 dark:border-slate-700/60 rounded-xl p-1 pr-2.5">
            <button
              onClick={() => syncFromCloud(false)}
              className={`p-1.5 rounded-lg transition-all duration-300 cursor-pointer ${
                syncStatus === 'syncing'
                  ? 'bg-blue-500/10 text-blue-500'
                  : syncStatus === 'success'
                  ? 'bg-emerald-500/10 text-emerald-500 hover:bg-emerald-500/20'
                  : syncStatus === 'error'
                  ? 'bg-rose-500/10 text-rose-500 hover:bg-rose-500/20'
                  : 'bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
              }`}
              title="Бұлттық базамен синхрондауды жаңарту"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
            </button>
            <div className="text-left leading-none">
              <p className="text-[7px] uppercase tracking-wider font-extrabold text-slate-400 dark:text-slate-500">Бұлттық База</p>
              <span className={`text-[9px] font-black ${
                syncStatus === 'syncing' ? 'text-blue-500' :
                syncStatus === 'success' ? 'text-emerald-500 animate-pulse' :
                syncStatus === 'error' ? 'text-rose-500' : 'text-slate-500'
              }`}>
                {syncStatus === 'syncing' ? 'Жүктелуде...' :
                 syncStatus === 'success' ? 'База: Белсенді' :
                 syncStatus === 'error' ? 'Қате / Офлайн' : 'Дайын'}
              </span>
            </div>
          </div>

          {/* Quick theme toggler */}
          <button
            onClick={() => setIsDarkMode(!isDarkMode)}
            className="p-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200/40 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:scale-105 transition cursor-pointer"
            title="Тақырыпты өзгерту"
          >
            {isDarkMode ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>

          {/* Quick notifications bell */}
          <button
            onClick={() => {
              setBottomSheetType('notifications');
              setBottomSheetOpen(true);
            }}
            className="p-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200/40 dark:border-slate-700 text-slate-600 dark:text-slate-300 relative cursor-pointer"
          >
            <Bell className="w-4 h-4" />
            <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-teal-500 animate-ping" />
          </button>

          {/* Logout Button */}
          <button
            onClick={handleLogout}
            className="hidden sm:flex items-center gap-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-950/30 dark:hover:bg-rose-900/30 text-rose-600 border border-rose-100 dark:border-rose-900/30 rounded-xl px-3.5 py-1.5 text-xs font-bold transition cursor-pointer"
          >
            <LogOut className="w-3.5 h-3.5" />
            Шығу
          </button>
        </div>

      </header>

      {/* MAIN LAYOUT WRAPPER */}
      <div className="max-w-7xl mx-auto p-4 lg:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* PHONE SIMULATOR PANEL (Displays the precise mobile app code they designed, fully interactive!) */}
        {(viewLayout === 'split' || viewLayout === 'phone-only') && (
          <div className="col-span-1 lg:col-span-4 flex justify-center">
            
            {/* Mobile phone frame casing */}
            <div className="w-full max-w-[365px] bg-slate-950 rounded-[45px] p-3.5 border-[6px] border-slate-850 shadow-2xl relative overflow-hidden text-slate-100">
              
              {/* Dynamic island / speaker grill */}
              <div className="absolute top-5 left-1/2 -translate-x-1/2 w-28 h-5 bg-black rounded-full z-50 flex items-center justify-center">
                <div className="w-12 h-1 bg-slate-900 rounded-full" />
                <div className="w-2.5 h-2.5 bg-indigo-950 rounded-full ml-2 border border-slate-900" />
              </div>

              {/* Glowing aurora inside phone */}
              <div className="absolute top-10 left-[-50px] w-48 h-48 bg-teal-500/10 rounded-full blur-[40px] pointer-events-none" />
              <div className="absolute bottom-10 right-[-50px] w-48 h-48 bg-indigo-500/10 rounded-full blur-[40px] pointer-events-none" />

              {/* Status Bar */}
              <div className="flex justify-between px-6 pt-3 pb-1 text-3xs font-mono text-slate-400 select-none items-center relative z-40">
                <span>12:10 PM</span>
                <div className="flex gap-1.5 items-center">
                  <span className="w-3 h-2 border border-slate-500 rounded-xs flex items-center p-0.5"><span className="h-full w-2 bg-slate-400 rounded-2xs" /></span>
                  <span className="text-[8px]">LTE</span>
                </div>
              </div>

              {/* Phone app interactive body */}
              <div className="rounded-[35px] bg-slate-900/90 border border-slate-800 min-h-[580px] flex flex-col justify-between relative overflow-hidden pt-4 pb-2">
                
                {/* Phone Header */}
                <div className="px-4 py-2 flex justify-between items-center border-b border-slate-800/40">
                  <button 
                    onClick={() => setSideMenuOpen(!sideMenuOpen)}
                    className="p-1.5 bg-slate-800/80 rounded-lg border border-slate-700/50 hover:bg-slate-700/80 cursor-pointer"
                  >
                    <Menu className="w-3.5 h-3.5 text-slate-200" />
                  </button>
                  <div className="text-center">
                    <p className="text-[9px] font-black tracking-widest text-teal-400">JUMA UI</p>
                    <h4 className="text-xs font-bold text-white capitalize">
                      {activeTab === 'home' ? 'Басты бет' : 
                       activeTab === 'orders' ? 'Тапсырыстар' :
                       activeTab === 'clients' ? 'Клиенттер' :
                       activeTab === 'inventory' ? 'Қойма' :
                       activeTab === 'reports' ? 'Есептер' :
                       activeTab === 'employees' ? 'Бонус' :
                       activeTab === 'measurements' ? 'Замер' : '3D Модель'}
                    </h4>
                  </div>
                  <button 
                    onClick={() => {
                      setBottomSheetType('notifications');
                      setBottomSheetOpen(true);
                    }}
                    className="p-1.5 bg-slate-800/80 rounded-lg border border-slate-700/50 hover:bg-slate-700/80 cursor-pointer"
                  >
                    <Bell className="w-3.5 h-3.5 text-slate-200" />
                  </button>
                </div>

                {/* Phone scrollable screen panels */}
                <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4 max-h-[460px] scrollbar-thin">
                  
                  {activeTab === 'home' ? (
                    <div className="space-y-4">
                      
                      {/* Premium welcome solid color card styled exactly like the user's design */}
                      <div className="bg-gradient-to-r from-blue-600 via-indigo-600 to-indigo-700 text-white rounded-3xl p-5 shadow-lg shadow-indigo-600/15 relative overflow-hidden">
                        {/* Decorative background vectors */}
                        <div className="absolute right-[-20px] top-[-20px] w-32 h-32 bg-white/10 rounded-full blur-xl pointer-events-none" />
                        <div className="absolute left-[-20px] bottom-[-20px] w-24 h-24 bg-white/5 rounded-full blur-lg pointer-events-none" />
                        
                        <div className="flex gap-4 items-center relative z-10">
                          <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white shadow-inner">
                            <Layout className="w-6 h-6 animate-pulse" />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/70 font-semibold uppercase tracking-widest">Сәлеметсіз бе,</p>
                            <h3 className="text-lg font-black tracking-tight mt-0.5">Директор</h3>
                            <span className="text-[10px] bg-emerald-500/30 text-emerald-200 px-2 py-0.5 rounded-full font-medium inline-block mt-1">Жүйеге сәтті кірдіңіз</span>
                          </div>
                        </div>
                      </div>

                      {/* Phone Stats summaries */}
                      <div className="grid grid-cols-2 gap-2.5">
                        <div className="bg-white/5 dark:bg-slate-800/40 border border-slate-200/10 dark:border-slate-800/80 p-3.5 rounded-2xl shadow-sm">
                          <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Жалпы айналым</p>
                          <h4 className="text-sm font-black text-blue-400 font-mono mt-1">{financialStats.totalRevenue.toLocaleString()} ₸</h4>
                        </div>
                        <div className="bg-white/5 dark:bg-slate-800/40 border border-slate-200/10 dark:border-slate-800/80 p-3.5 rounded-2xl shadow-sm">
                          <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Нақты касса</p>
                          <h4 className="text-sm font-black text-emerald-400 font-mono mt-1">{financialStats.totalPaid.toLocaleString()} ₸</h4>
                        </div>
                      </div>

                      {/* Quick modules jump grid - Designed beautifully as bento grid cards */}
                      <div>
                        <div className="flex justify-between items-center mb-2.5">
                          <h4 className="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Негізгі модульдер</h4>
                          <span className="text-[8px] font-bold text-indigo-400 uppercase">Оңтайландырылған</span>
                        </div>
                        <div className="grid grid-cols-3 gap-2.5">
                          {[
                            { id: 'orders', label: 'Тапсырыс', icon: Package, color: 'text-blue-400 bg-blue-500/10 border-blue-500/20' },
                            { id: 'clients', label: 'Клиенттер', icon: Users, color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20' },
                            { id: '3d', label: 'Өнімдер', icon: Sparkles, color: 'text-purple-400 bg-purple-500/10 border-purple-500/20' },
                            { id: 'inventory', label: 'Қойма', icon: Package, color: 'text-amber-400 bg-amber-500/10 border-amber-500/20' },
                            { id: 'reports', label: 'Есептер', icon: BarChart3, color: 'text-cyan-400 bg-cyan-500/10 border-cyan-500/20' },
                            { id: 'employees', label: 'Бонустар', icon: Users2, color: 'text-rose-400 bg-rose-500/10 border-rose-500/20' },
                          ].map(item => (
                            <button
                              key={item.id}
                              onClick={() => setActiveTab(item.id as typeof activeTab)}
                              className="bg-slate-800/40 hover:bg-slate-800/80 border border-slate-800/60 rounded-2xl p-3 flex flex-col items-center text-center gap-2 cursor-pointer transition-all duration-200 hover:-translate-y-1 active:scale-95 shadow-sm"
                            >
                              <div className={`p-2 rounded-xl ${item.color} border flex items-center justify-center`}>
                                <item.icon className="w-4 h-4" />
                              </div>
                              <span className="text-[9px] font-black tracking-tight text-slate-200">{item.label}</span>
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Cabinet 3D Design Promo card */}
                      <button 
                        onClick={() => setActiveTab('3d')}
                        className="w-full bg-gradient-to-r from-teal-500/20 to-indigo-500/20 hover:from-teal-500/25 hover:to-indigo-500/25 border border-teal-500/30 rounded-2xl p-4 text-left relative overflow-hidden transition cursor-pointer group"
                      >
                        <div className="absolute right-[-15px] bottom-[-15px] opacity-15 group-hover:scale-110 transition-transform">
                          <Layout className="w-24 h-24 text-teal-400" />
                        </div>
                        <span className="px-2 py-0.5 bg-teal-500/20 border border-teal-500/30 rounded text-[8px] font-bold text-teal-300 uppercase tracking-wider">
                          Интерактивті
                        </span>
                        <h4 className="text-xs font-bold text-white mt-1.5">3D Жиһаз Конструкторы</h4>
                        <p className="text-[9px] text-slate-400 mt-1 max-w-[190px]">
                          Материал, фурнитура және өлшемін таңдап, бұйым құнын бірден есептеңіз!
                        </p>
                      </button>

                    </div>
                  ) : activeTab === 'orders' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">Тапсырыстар тізімі ({orders.length})</p>
                      <div className="space-y-2">
                        {orders.map(o => (
                          <div 
                            key={o.id} 
                            onClick={() => {
                              setSelectedOrderDetail(o);
                              setBottomSheetType('order_detail');
                              setBottomSheetOpen(true);
                            }}
                            className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl space-y-2 cursor-pointer hover:bg-slate-800/80 transition"
                          >
                            <div className="flex justify-between items-center text-[10px]">
                              <span className="font-bold font-mono text-teal-400">{o.id}</span>
                              <span className="px-1.5 py-0.5 rounded-full bg-teal-500/10 text-teal-400 font-bold uppercase">{STATUS_KAZAKH[o.status]}</span>
                            </div>
                            <div>
                              <h5 className="text-xs font-bold text-white">{o.clientName}</h5>
                              <p className="text-[9px] text-slate-400">{o.productType} • {o.price.toLocaleString()} ₸</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : activeTab === 'clients' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">Клиент базасы ({clients.length})</p>
                      <div className="space-y-2">
                        {clients.map(c => (
                          <div key={c.id} className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl">
                            <h5 className="text-xs font-bold text-white">{c.name}</h5>
                            <p className="text-[9px] text-slate-400 font-mono">{c.phone}</p>
                            <p className="text-[9px] text-teal-400 mt-1.5 font-bold">LTV: {c.totalSpent.toLocaleString()} ₸</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : activeTab === 'inventory' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">Қойма қалдығы</p>
                      <div className="space-y-2">
                        {inventory.map(item => (
                          <div key={item.id} className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl flex justify-between items-center text-xs">
                            <div>
                              <p className="font-bold text-white text-xxs">{item.name}</p>
                              <span className="text-[9px] text-slate-400">{item.unit}</span>
                            </div>
                            <span className="font-bold font-mono text-teal-400">{item.quantity}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : activeTab === 'reports' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold font-sans">Жылдам есеп талдау</p>
                      <div className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl space-y-2 text-xxs">
                        <div className="flex justify-between">
                          <span>Жалпы сауда:</span>
                          <strong className="font-mono text-teal-400">{financialStats.totalRevenue.toLocaleString()} ₸</strong>
                        </div>
                        <div className="flex justify-between">
                          <span>Нақты кіріс (Касса):</span>
                          <strong className="font-mono text-emerald-400">{financialStats.totalPaid.toLocaleString()} ₸</strong>
                        </div>
                        <div className="flex justify-between">
                          <span>Дебиторлық берешек:</span>
                          <strong className="font-mono text-amber-500">{(financialStats.totalRevenue - financialStats.totalPaid).toLocaleString()} ₸</strong>
                        </div>
                      </div>
                    </div>
                  ) : activeTab === 'employees' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">Қызметкерлер тізімі ({employees.length})</p>
                      <div className="space-y-2">
                        {employees.map(emp => (
                          <div key={emp.id} className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl flex justify-between items-center text-xxs">
                            <div>
                              <p className="font-bold text-white">{emp.name}</p>
                              <span className="text-[9px] text-slate-400">{emp.role}</span>
                            </div>
                            <span className="font-bold text-rose-400 font-mono">{emp.totalBonuses.toLocaleString()} ₸</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : activeTab === 'measurements' ? (
                    <div className="space-y-4">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">Өлшеу кестесі</p>
                      <div className="space-y-2">
                        {measurements.map(m => (
                          <div key={m.id} className="bg-slate-800/40 border border-slate-800 p-3 rounded-xl space-y-1">
                            <div className="flex justify-between text-[10px]">
                              <span className="font-bold text-white">{m.clientName}</span>
                              <span className="text-slate-400">{m.date}</span>
                            </div>
                            <p className="text-[9px] text-slate-400">{m.address}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      <p className="text-[10px] text-slate-400 uppercase tracking-widest font-bold font-sans">Дизайн жобалау залы</p>
                      <div className="bg-slate-800/50 rounded-xl p-3 text-center border border-slate-850 space-y-2">
                        <Layout className="w-12 h-12 text-blue-400 mx-auto animate-pulse" />
                        <h4 className="text-xs font-bold text-white">3D Модельдеу Белсенді</h4>
                        <p className="text-[9px] text-slate-400 leading-normal">
                          Бұл модельдеу модулі компьютер экранында оңтайландырылған. Толық басқару үшін оң жақтағы компьютер терезесін пайдаланыңыз!
                        </p>
                      </div>
                    </div>
                  )}

                </div>

                {/* Phone bottom action navigation bar (Prerendered with selection indicators) */}
                <div className="px-3 pb-3 pt-1 bg-slate-900 relative z-40">
                  <nav className="bg-slate-950/90 border border-slate-800/80 backdrop-blur-md rounded-2xl py-2 px-3 flex justify-between items-center relative select-none">
                    
                    <button 
                      onClick={() => setActiveTab('home')}
                      className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                        activeTab === 'home' 
                          ? 'text-blue-400 scale-105 font-bold' 
                          : 'text-slate-500 hover:text-slate-300'
                      }`}
                    >
                      <div className={`p-1.5 rounded-xl transition ${activeTab === 'home' ? 'bg-blue-500/10' : ''}`}>
                        <Layout className="w-4 h-4" />
                      </div>
                      <span className="text-[8px]">Басты бет</span>
                    </button>

                    <button 
                      onClick={() => setActiveTab('orders')}
                      className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                        activeTab === 'orders' 
                          ? 'text-blue-400 scale-105 font-bold' 
                          : 'text-slate-500 hover:text-slate-300'
                      }`}
                    >
                      <div className={`p-1.5 rounded-xl transition ${activeTab === 'orders' ? 'bg-blue-500/10' : ''}`}>
                        <Package className="w-4 h-4" />
                      </div>
                      <span className="text-[8px]">Тапсырыс</span>
                    </button>

                    {/* Phone Middle Floating Action Button (FAB) */}
                    <button 
                      onClick={() => {
                        setActiveTab('orders');
                        setShowAddOrderForm(true);
                      }}
                      className="w-11 h-11 bg-gradient-to-r from-blue-500 via-indigo-600 to-teal-500 text-white rounded-full flex items-center justify-center shadow-[0_4px_15px_rgba(99,102,241,0.4)] hover:scale-105 active:scale-95 transition-all duration-300 cursor-pointer z-50 border-2 border-slate-950 -translate-y-5 animate-pulse"
                      style={{ animationDuration: '3s' }}
                    >
                      <Plus className="w-6 h-6 font-black" />
                    </button>

                    <button 
                      onClick={() => setActiveTab('inventory')}
                      className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                        activeTab === 'inventory' 
                          ? 'text-blue-400 scale-105 font-bold' 
                          : 'text-slate-500 hover:text-slate-300'
                      }`}
                    >
                      <div className={`p-1.5 rounded-xl transition ${activeTab === 'inventory' ? 'bg-blue-500/10' : ''}`}>
                        <Users className="w-4 h-4" />
                      </div>
                      <span className="text-[8px]">Қойма</span>
                    </button>

                    <button 
                      onClick={() => setActiveTab('3d')}
                      className={`flex flex-col items-center gap-1 cursor-pointer transition-all duration-200 ${
                        activeTab === '3d' 
                          ? 'text-blue-400 scale-105 font-bold' 
                          : 'text-slate-500 hover:text-slate-300'
                      }`}
                    >
                      <div className={`p-1.5 rounded-xl transition ${activeTab === '3d' ? 'bg-blue-500/10' : ''}`}>
                        <Compass className="w-4 h-4" />
                      </div>
                      <span className="text-[8px]">3D</span>
                    </button>

                  </nav>
                </div>

                {/* SLIDING SIDE DRAWER MENU (From their mobile design) */}
                {sideMenuOpen && (
                  <div className="absolute inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity">
                    <div className="absolute bottom-0 left-0 right-0 bg-slate-900 border-t border-slate-800 rounded-t-3xl p-5 space-y-4 max-h-[380px] overflow-y-auto animate-slideUp">
                      <div className="w-12 h-1.5 bg-slate-700 rounded-full mx-auto" />
                      <h3 className="font-bold text-sm text-teal-400">JUMA UI мәзірі</h3>
                      
                      <div className="grid grid-cols-1 gap-2 text-xs">
                        <button onClick={() => handleMenuJump('orders')} className="w-full text-left bg-slate-800 hover:bg-slate-750 p-3 rounded-xl transition cursor-pointer">Тапсырыстарды бақылау</button>
                        <button onClick={() => handleMenuJump('clients')} className="w-full text-left bg-slate-800 hover:bg-slate-750 p-3 rounded-xl transition cursor-pointer">Клиенттер базасы</button>
                        <button onClick={() => handleMenuJump('measurements')} className="w-full text-left bg-slate-800 hover:bg-slate-750 p-3 rounded-xl transition cursor-pointer">Замер базасы (Өлшем)</button>
                        <button onClick={() => handleMenuJump('employees')} className="w-full text-left bg-slate-800 hover:bg-slate-750 p-3 rounded-xl transition cursor-pointer">Бонус және Қызметкерлер</button>
                        <button onClick={() => handleMenuJump('reports')} className="w-full text-left bg-slate-800 hover:bg-slate-750 p-3 rounded-xl transition cursor-pointer">Есеп аналитикасы</button>
                      </div>

                      <button 
                        onClick={() => setSideMenuOpen(false)}
                        className="w-full bg-slate-800 hover:bg-slate-700 py-3 rounded-xl text-xs font-bold text-slate-300 transition cursor-pointer"
                      >
                        Жабу
                      </button>
                    </div>
                  </div>
                )}

                {/* BOTTOM SHEET DRAWER (From their mobile design) */}
                {bottomSheetOpen && (
                  <div className="absolute inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity flex items-end">
                    <div className="w-full bg-slate-900 border-t border-slate-800 rounded-t-3xl p-5 space-y-4 max-h-[400px] overflow-y-auto animate-slideUp">
                      
                      {/* Drag handle decoration */}
                      <div className="w-12 h-1.5 bg-slate-700 rounded-full mx-auto cursor-pointer" onClick={() => setBottomSheetOpen(false)} />

                      {bottomSheetType === 'add_fast' ? (
                        <div className="space-y-4">
                          <div className="space-y-1">
                            <span className="text-[10px] font-black tracking-widest text-teal-400 uppercase">Жаңа әрекет</span>
                            <h3 className="font-bold text-sm text-white">Жылдам Тапсырыс Қосу</h3>
                            <p className="text-[9px] text-slate-400">Алдын ала таңдалған жиһаз үлгілерін бірден тіркеңіз:</p>
                          </div>

                          <div className="space-y-2 text-xs">
                            <button onClick={() => handleFastAddAction('Ас үй гарнитуры (MDF)', 850000)} className="w-full flex justify-between items-center bg-slate-850 hover:bg-slate-800 p-3 rounded-xl transition cursor-pointer">
                              <span>Ас үй гарнитуры (MDF)</span>
                              <strong className="text-teal-400">850К ₸</strong>
                            </button>
                            <button onClick={() => handleFastAddAction('Шкаф-купе Премиум', 480000)} className="w-full flex justify-between items-center bg-slate-850 hover:bg-slate-800 p-3 rounded-xl transition cursor-pointer">
                              <span>Шкаф-купе Премиум</span>
                              <strong className="text-teal-400">480К ₸</strong>
                            </button>
                            <button onClick={() => handleFastAddAction('ТВ консоль / Комод', 120000)} className="w-full flex justify-between items-center bg-slate-850 hover:bg-slate-800 p-3 rounded-xl transition cursor-pointer">
                              <span>ТВ консоль / Комод</span>
                              <strong className="text-teal-400">120К ₸</strong>
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div className="space-y-4">
                          <h3 className="font-bold text-sm text-white">Қызметтік Хабарламалар</h3>
                          <div className="space-y-2 text-xxs text-slate-300">
                            <div className="p-2.5 bg-slate-800 rounded-lg border-l-2 border-teal-500">
                              <p className="font-semibold text-white">Жаңа тапсырыс келіп түсті</p>
                              <span className="text-slate-400 text-3xs">10 минут бұрын</span>
                            </div>
                            <div className="p-2.5 bg-slate-800 rounded-lg border-l-2 border-amber-500">
                              <p className="font-semibold text-white">Қоймада поролон қалдығы аз!</p>
                              <span className="text-slate-400 text-3xs">2 сағат бұрын</span>
                            </div>
                          </div>
                        </div>
                      )}

                      <button 
                        onClick={() => setBottomSheetOpen(false)}
                        className="w-full bg-slate-800 hover:bg-slate-700 py-2.5 rounded-xl text-xs font-bold text-slate-300 transition cursor-pointer"
                      >
                        Жабу
                      </button>
                    </div>
                  </div>
                )}

              </div>

            </div>

          </div>
        )}

        {/* FULL DESKTOP PRO WORKSPACE (Features beautiful custom panels and linked data operations) */}
        {(viewLayout === 'split' || viewLayout === 'desktop-only') && (
          <div className="col-span-1 lg:col-span-8 space-y-6">
            
            {/* Navigational Tabs row */}
            <div className={`flex p-1.5 rounded-2xl gap-2 overflow-x-auto border ${
              isDarkMode ? 'glass-moldyr-dark bg-slate-900/40 border-sky-500/10' : 'glass-moldyr-light bg-white/40 border-white/50'
            }`}>
              {[
                { id: 'home', label: 'Басты бет', icon: Layout },
                { id: 'orders', label: 'Тапсырыстар', icon: Package },
                { id: 'clients', label: 'Клиенттер базасы', icon: Users },
                { id: 'inventory', label: 'Қойма / Материалдар', icon: Database },
                { id: 'reports', label: 'Есептер / Статистика', icon: TrendingUp },
                { id: 'employees', label: 'Қызметкерлер', icon: UsersRound },
                { id: 'measurements', label: 'Замер Күнтізбесі', icon: Compass },
                { id: '3d', label: 'Интерактивті 3D', icon: Box },
              ].map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as typeof activeTab)}
                    className={`px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap transition cursor-pointer flex items-center gap-1.5 ${
                      activeTab === tab.id 
                        ? 'bg-gradient-to-r from-blue-600 to-indigo-600 dark:from-sky-500 dark:to-blue-600 text-white shadow-md' 
                        : 'text-slate-500 dark:text-slate-400 hover:bg-slate-50/50 dark:hover:bg-slate-800/50'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </div>

            {/* Desktop Dashboard Screen router */}
            <div className={`rounded-3xl p-6 min-h-[500px] shadow-lg border transition-all duration-300 ${
              isDarkMode ? 'glass-moldyr-dark' : 'glass-moldyr-light'
            }`}>
              
              {activeTab === 'home' && (
                <div className="space-y-6 animate-fadeIn">
                  
                  {/* Dashboard Header welcome */}
                  <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-gradient-to-r from-sky-400/20 via-blue-500/10 to-indigo-500/5 dark:from-sky-400/10 dark:via-blue-500/5 dark:to-transparent border border-sky-400/30 dark:border-sky-500/15 rounded-3xl p-6 relative overflow-hidden shadow-inner">
                    <div>
                      <span className="text-xs text-blue-600 dark:text-sky-400 font-bold uppercase tracking-widest flex items-center gap-1">
                        <Sparkles className="w-3.5 h-3.5" /> JUMA UI Мебель CRM Pro
                      </span>
                      <h2 className="text-xl font-black text-slate-850 dark:text-white mt-1">Директор кабинетіне қош келдіңіз!</h2>
                      <p className="text-xs text-slate-500 mt-0.5">Кәсіпорынның барлық көрсеткіштері мен тапсырыстары осында басқарылады.</p>
                    </div>
                  </div>

                  {/* Financial metrics charts row */}
                  <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                    <div className={`p-4 rounded-2xl border transition-all duration-300 hover:-translate-y-0.5 ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Айлық Түсім (Жалпы)</span>
                      <h3 className="text-xl font-black font-mono text-slate-850 dark:text-white mt-1">
                        {financialStats.totalRevenue.toLocaleString()} ₸
                      </h3>
                      <span className="text-xxs text-emerald-500 font-medium">+18% Өсім деңгейі</span>
                    </div>

                    <div className={`p-4 rounded-2xl border transition-all duration-300 hover:-translate-y-0.5 ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Касса (Төленгені)</span>
                      <h3 className="text-xl font-black font-mono text-blue-600 dark:text-sky-400 mt-1">
                        {financialStats.totalPaid.toLocaleString()} ₸
                      </h3>
                      <span className="text-xxs text-slate-400">Нақты қолма-қол ақша</span>
                    </div>

                    <div className={`p-4 rounded-2xl border transition-all duration-300 hover:-translate-y-0.5 ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Белсенді Тапсырыстар</span>
                      <h3 className="text-xl font-black font-mono text-slate-850 dark:text-white mt-1">
                        {financialStats.activeCount} бұйым
                      </h3>
                      <span className="text-xxs text-slate-400">Өндірісте немесе жеткізуде</span>
                    </div>

                    <div className={`p-4 rounded-2xl border transition-all duration-300 hover:-translate-y-0.5 ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <span className="text-xxs uppercase tracking-wider font-semibold text-slate-400">Клиент Базасы</span>
                      <h3 className="text-xl font-black font-mono text-slate-850 dark:text-white mt-1">
                        {financialStats.newClientsThisMonth} адам
                      </h3>
                      <span className="text-xxs text-slate-400">Тұрақты сатып алушылар</span>
                    </div>
                  </div>

                  {/* Promotion Panel */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className={`rounded-2xl p-5 border flex justify-between items-center transition-all ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <div className="space-y-1">
                        <span className="text-xxs font-bold text-blue-600 dark:text-sky-400 uppercase tracking-widest">Интерактивті 3D</span>
                        <h4 className="text-sm font-bold text-slate-805 dark:text-slate-100">Жиһаз құнын есептегіш</h4>
                        <p className="text-xxs text-slate-400 max-w-xs leading-normal">
                          Материал, фурнитура, столешница және өлшем арқылы ас үй мен шкафтардың өзіндік құнын нақты есептеңіз.
                        </p>
                        <button 
                          onClick={() => setActiveTab('3d')}
                          className="text-xs font-bold text-blue-600 dark:text-sky-400 flex items-center gap-1 pt-1.5 hover:underline cursor-pointer"
                        >
                          3D Конструкторға өту <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <Layout className="w-16 h-16 text-sky-500/20" />
                    </div>

                    <div className={`rounded-2xl p-5 border flex justify-between items-center transition-all ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10 hover:border-sky-400/20 shadow-md' : 'bg-white/60 border-sky-200/50 hover:border-sky-300/60 shadow-sm'
                    }`}>
                      <div className="space-y-1">
                        <span className="text-xxs font-bold text-blue-600 dark:text-sky-400 uppercase tracking-widest">Замер Базасы</span>
                        <h4 className="text-sm font-bold text-slate-805 dark:text-slate-100">Өлшеу (Замер) Күнтізбесі</h4>
                        <p className="text-xxs text-slate-400 max-w-xs leading-normal">
                          Замерщиктерді үйге жіберу күнін, уақытын және нақты бөлме өлшемдерін бір жерден бақылаңыз.
                        </p>
                        <button 
                          onClick={() => setActiveTab('measurements')}
                          className="text-xs font-bold text-blue-600 dark:text-sky-400 flex items-center gap-1 pt-1.5 hover:underline cursor-pointer"
                        >
                          Өлшеу базасын ашу <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <Compass className="w-16 h-16 text-sky-500/20" />
                    </div>
                  </div>

                  {/* Real-time Workshop Alert Centre & Critical Events */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-5 pt-2">
                    
                    {/* Critical Inventory Stock Alerts */}
                    <div className={`p-5 rounded-2xl border ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10' : 'bg-white/60 border-slate-100'
                    } space-y-3 shadow-sm`}>
                      <div className="flex justify-between items-center pb-2 border-b border-slate-100/10">
                        <h4 className="text-xs font-black text-slate-800 dark:text-white uppercase tracking-wider flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
                          Қойма қалдығы аз
                        </h4>
                        <button 
                          onClick={() => setActiveTab('inventory')}
                          className="text-[10px] font-bold text-blue-600 dark:text-sky-400 hover:underline cursor-pointer"
                        >
                          Барлығы
                        </button>
                      </div>

                      <div className="space-y-2">
                        {inventory.filter(item => item.quantity <= item.minQuantity).slice(0, 3).map(item => (
                          <div key={item.id} className="flex justify-between items-center text-3xs font-mono border-b border-dashed border-slate-100/10 pb-1.5">
                            <span className="text-slate-700 dark:text-slate-300 font-sans font-semibold truncate max-w-[140px]">{item.name}</span>
                            <div className="text-right">
                              <span className="text-rose-500 font-extrabold">{item.quantity} {item.unit}</span>
                              <span className="text-slate-400 block text-[8px]">Минимум: {item.minQuantity}</span>
                            </div>
                          </div>
                        ))}
                        {inventory.filter(item => item.quantity <= item.minQuantity).length === 0 && (
                          <div className="text-center py-6 text-slate-400 text-xxs italic">
                            Қауіпті қалдық деңгейлері жоқ. Барлығы жеткілікті! ✔
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Upcoming measurements */}
                    <div className={`p-5 rounded-2xl border ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10' : 'bg-white/60 border-slate-100'
                    } space-y-3 shadow-sm`}>
                      <div className="flex justify-between items-center pb-2 border-b border-slate-100/10">
                        <h4 className="text-xs font-black text-slate-800 dark:text-white uppercase tracking-wider flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse" />
                          Жоспарлы замерлер
                        </h4>
                        <button 
                          onClick={() => setActiveTab('measurements')}
                          className="text-[10px] font-bold text-blue-600 dark:text-sky-400 hover:underline cursor-pointer"
                        >
                          Күнтізбе
                        </button>
                      </div>

                      <div className="space-y-2">
                        {measurements.filter(m => m.status === 'scheduled').slice(0, 3).map(m => (
                          <div key={m.id} className="flex justify-between items-center text-3xs font-mono border-b border-dashed border-slate-100/10 pb-1.5">
                            <div className="font-sans">
                              <span className="text-slate-700 dark:text-slate-300 font-semibold truncate max-w-[120px] block">{m.clientName}</span>
                              <span className="text-slate-400 text-[8px] block">{m.address}</span>
                            </div>
                            <div className="text-right font-mono text-indigo-500 dark:text-indigo-400 font-extrabold">
                              <span>{m.date}</span>
                              <span className="text-slate-400 block text-[8px]">{m.time}</span>
                            </div>
                          </div>
                        ))}
                        {measurements.filter(m => m.status === 'scheduled').length === 0 && (
                          <div className="text-center py-6 text-slate-400 text-xxs italic">
                            Алғашқы күндерге жоспарланған замерлер жоқ.
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Recent high value active orders */}
                    <div className={`p-5 rounded-2xl border ${
                      isDarkMode ? 'bg-slate-950/45 border-sky-500/10' : 'bg-white/60 border-slate-100'
                    } space-y-3 shadow-sm`}>
                      <div className="flex justify-between items-center pb-2 border-b border-slate-100/10">
                        <h4 className="text-xs font-black text-slate-800 dark:text-white uppercase tracking-wider flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                          Соңғы белсенді тапсырыстар
                        </h4>
                        <button 
                          onClick={() => setActiveTab('orders')}
                          className="text-[10px] font-bold text-blue-600 dark:text-sky-400 hover:underline cursor-pointer"
                        >
                          Барлығы
                        </button>
                      </div>

                      <div className="space-y-2">
                        {orders.filter(o => o.status !== 'completed' && o.status !== 'cancelled').slice(0, 3).map(o => {
                          const statusLabels = {
                            new: 'Жаңа',
                            measurement: 'Замер',
                            production: 'Өндірісте',
                            delivery: 'Жеткізуде'
                          };
                          return (
                            <div key={o.id} className="flex justify-between items-center text-3xs font-mono border-b border-dashed border-slate-100/10 pb-1.5">
                              <div>
                                <span className="text-slate-700 dark:text-slate-300 font-sans font-bold truncate max-w-[120px] block">{o.clientName}</span>
                                <span className="text-slate-400 text-[8px] font-sans truncate max-w-[120px] block">{o.productType}</span>
                              </div>
                              <div className="text-right font-mono">
                                <span className="text-emerald-500 font-extrabold">{o.price.toLocaleString()} ₸</span>
                                <span className="text-slate-400 block text-[8px] font-sans">
                                  {statusLabels[o.status as keyof typeof statusLabels] || o.status}
                                </span>
                              </div>
                            </div>
                          );
                        })}
                        {orders.filter(o => o.status !== 'completed' && o.status !== 'cancelled').length === 0 && (
                          <div className="text-center py-6 text-slate-400 text-xxs italic">
                            Ағымдағы белсенді тапсырыстар тізімі бос.
                          </div>
                        )}
                      </div>
                    </div>

                  </div>

                </div>
              )}

              {activeTab === 'orders' && (
                <OrdersModule 
                  orders={orders} 
                  employees={employees}
                  onAddOrder={addOrder} 
                  onUpdateOrder={updateOrder} 
                  onDeleteOrder={deleteOrder}
                  onShowToast={triggerToast}
                  showAddFormProp={showAddOrderForm}
                  onShowAddFormChange={setShowAddOrderForm}
                />
              )}

              {activeTab === 'clients' && (
                <ClientsModule 
                  clients={clients} 
                  orders={orders}
                  onAddClient={addClient}
                  onShowToast={triggerToast}
                />
              )}

              {activeTab === 'inventory' && (
                <InventoryModule 
                  inventory={inventory} 
                  onUpdateInventory={updateInventory}
                  onShowToast={triggerToast}
                />
              )}

              {activeTab === 'reports' && (
                <ReportsModule 
                  orders={orders} 
                  clients={clients} 
                  inventory={inventory}
                  employees={employees}
                  measurements={measurements}
                />
              )}

              {activeTab === 'employees' && (
                <EmployeesModule 
                  employees={employees} 
                  onRewardBonus={rewardEmployeeBonus}
                  onShowToast={triggerToast}
                />
              )}

              {activeTab === 'measurements' && (
                <MeasurementsModule 
                  measurements={measurements} 
                  onAddMeasurement={addMeasurement}
                  onUpdateMeasurement={updateMeasurement}
                  onShowToast={triggerToast}
                />
              )}

              {activeTab === '3d' && (
                <Visualizer3D 
                  onAddOrderFromConfig={handleAddOrderFrom3D} 
                  onShowToast={triggerToast}
                />
              )}

            </div>

          </div>
        )}

      </div>

      {/* TOAST NOTIFICATION ALERTS */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 bg-slate-900 dark:bg-white text-white dark:text-slate-900 border border-slate-800 dark:border-slate-100 rounded-2xl px-5 py-3 shadow-2xl z-50 flex items-center gap-2 animate-fadeIn text-xs font-bold">
          <span className="w-2 h-2 rounded-full bg-teal-500 animate-pulse" />
          {toastMessage}
        </div>
      )}

    </div>
  );
}

// Quick Mock Box Icon to fallback if not imported
function BoxIcon(props: any) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
      <line x1="12" y1="22.08" x2="12" y2="12" />
    </svg>
  );
}
