import React, { useState } from 'react';
import { Client, Order } from '../types';
import { Search, Plus, UserPlus, Phone, MapPin, Mail, Award, DollarSign, Calendar } from 'lucide-react';

interface ClientsModuleProps {
  clients: Client[];
  orders: Order[];
  onAddClient: (client: Client) => void;
  onShowToast: (msg: string) => void;
}

export default function ClientsModule({ clients, orders, onAddClient, onShowToast }: ClientsModuleProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  
  // Form State
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');

  const filteredClients = clients.filter(client => 
    client.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    client.phone.includes(searchTerm) || 
    (client.address && client.address.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !phone || !address) {
      onShowToast('Аты-жөні, телефоны және мекенжайын толтырыңыз');
      return;
    }

    const newClient: Client = {
      id: `CLI-${Math.floor(100 + Math.random() * 900)}`,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim() || undefined,
      address: address.trim(),
      totalOrders: 0,
      totalSpent: 0,
      createdAt: new Date().toISOString(),
      notes: notes.trim() || undefined
    };

    onAddClient(newClient);
    onShowToast('Клиент базаға сәтті қосылды!');
    setShowAddForm(false);
    
    // reset
    setName('');
    setPhone('');
    setEmail('');
    setAddress('');
    setNotes('');
  };

  return (
    <div className="space-y-6">
      
      {/* Module Title */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Клиенттер базасы</h2>
          <p className="text-xs text-slate-500">Клиенттермен жұмыс, тапсырыстар тарихы және байланыс деректері</p>
        </div>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="bg-teal-600 hover:bg-teal-700 text-white font-medium text-sm px-4 py-2.5 rounded-xl transition-all flex items-center gap-1.5 cursor-pointer shadow-sm active:scale-98"
        >
          <UserPlus className="w-4 h-4" />
          Жаңа клиент қосу
        </button>
      </div>

      {/* Add Client Form */}
      {showAddForm && (
        <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="col-span-1 md:col-span-2 pb-2 border-b border-slate-100 flex justify-between items-center">
            <h3 className="font-semibold text-slate-800">Жаңа клиент картасын тіркеу</h3>
            <button 
              type="button" 
              onClick={() => setShowAddForm(false)} 
              className="text-xs text-slate-400 hover:text-slate-600"
            >
              Болдырмау
            </button>
          </div>

          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-500">Аты-жөні (Толық) *</label>
            <input 
              type="text" 
              placeholder="Мысалы: Бауыржан Серіков" 
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
              required
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-500">Телефон нөмірі *</label>
            <input 
              type="tel" 
              placeholder="+7 701 123 4567" 
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
              required
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-500">Электронды пошта (Email)</label>
            <input 
              type="email" 
              placeholder="client@mail.ru" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-500">Мекенжайы (Жеткізу үшін) *</label>
            <input 
              type="text" 
              placeholder="Мысалы: Алматы қ., Абай даңғылы, 15" 
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 focus:outline-none"
              required
            />
          </div>

          <div className="col-span-1 md:col-span-2 space-y-1">
            <label className="text-xs font-semibold text-slate-500">Клиент туралы қосымша мәліметтер</label>
            <textarea 
              rows={2}
              placeholder="Байланыс ерекшеліктері, дизайн тілектері немесе басқа да маңызды ақпараттар" 
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 focus:outline-none"
            />
          </div>

          <div className="col-span-1 md:col-span-2 flex justify-end gap-2 pt-2">
            <button 
              type="submit" 
              className="bg-teal-600 hover:bg-teal-700 text-white font-medium text-sm px-5 py-2.5 rounded-xl transition shadow-sm cursor-pointer"
            >
              Клиентті Тіркеу
            </button>
          </div>
        </form>
      )}

      {/* Search Input */}
      <div className="relative">
        <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
        <input 
          type="text" 
          placeholder="Клиентті аты-жөні, телефоны немесе мекенжайы арқылы жылдам іздеу..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full bg-white border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-1 focus:ring-teal-500"
        />
      </div>

      {/* Clients grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredClients.map((client) => {
          // Calculate stats based on actual orders
          const clientOrders = orders.filter(o => o.clientName === client.name || o.clientPhone === client.phone);
          const ordersCount = clientOrders.length;
          const totalSpent = clientOrders.reduce((sum, o) => sum + o.price, 0);

          return (
            <div key={client.id} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm flex flex-col justify-between hover:shadow-md transition">
              <div className="space-y-4">
                
                {/* Client Profile Header */}
                <div className="flex justify-between items-start">
                  <div>
                    <span className="text-xxs font-mono bg-slate-100 text-slate-500 px-2 py-0.5 rounded uppercase font-black">
                      {client.id}
                    </span>
                    <h3 className="text-base font-bold text-slate-800 mt-1">{client.name}</h3>
                  </div>
                  {ordersCount > 1 && (
                    <span className="px-2 py-1 bg-amber-50 border border-amber-100 rounded text-amber-800 text-3xs uppercase font-black tracking-widest flex items-center gap-1">
                      <Award className="w-3 h-3 text-amber-500" /> V.I.P
                    </span>
                  )}
                </div>

                {/* Contacts & Delivery Address */}
                <div className="space-y-2 text-xs text-slate-600">
                  <div className="flex items-center gap-2">
                    <Phone className="w-3.5 h-3.5 text-slate-400" />
                    <span className="font-mono font-medium">{client.phone}</span>
                  </div>
                  {client.email && (
                    <div className="flex items-center gap-2">
                      <Mail className="w-3.5 h-3.5 text-slate-400" />
                      <span className="font-mono">{client.email}</span>
                    </div>
                  )}
                  <div className="flex items-start gap-2">
                    <MapPin className="w-3.5 h-3.5 text-slate-400 mt-0.5" />
                    <span>{client.address}</span>
                  </div>
                </div>

                {/* Notes about client */}
                {client.notes && (
                  <p className="bg-slate-50 border border-slate-100/80 p-2.5 rounded-xl text-xxs italic text-slate-500">
                    "{client.notes}"
                  </p>
                )}

                {/* Order logs / summaries */}
                <div className="border-t border-slate-50 pt-3 flex justify-between items-center bg-slate-50/50 rounded-xl p-3">
                  <div>
                    <span className="text-xxs font-semibold uppercase tracking-wider text-slate-400">Жалпы тапсырыс</span>
                    <p className="font-bold text-slate-800 text-sm">{ordersCount} дана</p>
                  </div>
                  <div className="text-right">
                    <span className="text-xxs font-semibold uppercase tracking-wider text-slate-400">Өмірлік құны (LTV)</span>
                    <p className="font-black text-teal-600 text-sm">{totalSpent.toLocaleString()} ₸</p>
                  </div>
                </div>

              </div>

              {/* Order history summary nested list */}
              {ordersCount > 0 && (
                <div className="mt-4 border-t border-slate-50 pt-3">
                  <span className="text-xxs font-bold text-slate-400 uppercase tracking-widest flex items-center gap-1 mb-2">
                    <Calendar className="w-3 h-3" /> Тапсырыстар тарихы:
                  </span>
                  <div className="space-y-1.5">
                    {clientOrders.map(o => (
                      <div key={o.id} className="flex justify-between items-center text-xxs font-mono text-slate-600 border-b border-dashed border-slate-100 pb-1">
                        <span className="truncate max-w-[180px] font-sans font-medium">{o.productType}</span>
                        <span className="font-bold text-slate-700">{o.price.toLocaleString()} ₸</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

            </div>
          );
        })}
      </div>

    </div>
  );
}
