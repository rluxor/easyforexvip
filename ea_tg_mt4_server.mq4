//+------------------------------------------------------------------+
//|                                                ea_mt4_server.mq4 |
//|                                                   RAUL LUCAS     |
//+------------------------------------------------------------------+
#property copyright "RAUL LUCAS"
#property version   "1.00"
#property description "Bot server to receive telegram messages"
#property strict

#include <Zmq/Zmq.mqh>

input int Socket_Port   = 5000;
input int Take_Profit   = 1;
input double Lots       = 0.01;
input int Max_Order     = 30;
input int MM_Type       = 2;      // 1-Fix Lot price , 2-Calculate fix lot per risk
input double MaxRiskPerTrade = 1; // % of balance to risk in one trade.
input int Slippage      = 3;

string label_name = "info_box";

//+------------------------------------------------------------------+
//|Initialize socket                                                 |
//+------------------------------------------------------------------+
Context context("mt4server");
Socket socket(context, ZMQ_REP);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   CreateLabels();

   string input_socket = "tcp://127.0.0.1:" + string(Socket_Port);
   socket.connect(input_socket);

   Print("Socket address: ", input_socket);
   Print("Server connected: ",socket.valid());
         
   SetText("info_box_socket", "Socket Address: " + input_socket);
   SetText("info_box_status", "Server connected: " + string(socket.valid()));
   SetText("info_box_orders", "Total Orders = " + string(OrdersTotal()));
   
   
   return(INIT_SUCCEEDED);
   
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
   clear(label_name);
  
   string input_socket = "tcp://127.0.0.1:" + string(Socket_Port);
   socket.disconnect(input_socket);
   
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   // Recibo el mensaje del middleware
   string requestedMessage = WaitForRequest();
   string ticketsOpened="";
   
   // Proceso el mensaje
   if(OrdersTotal() > Max_Order)
      Alert("Max Total Orders Reached: ",Max_Order);
   else
      ticketsOpened = SendNewOrder(requestedMessage);

   // Respondo al middleware con el resultado
   //ZmqMsg mensaje("Request processed: " + requestedMessage);
   ZmqMsg mensaje("Orders opened: " + ticketsOpened);
   socket.send(mensaje);
   
   SetText("info_box_status", "Server connected: " + string(socket.valid()));
   SetText("info_box_orders", "Total Orders = " + string(OrdersTotal()));

  }

string WaitForRequest()
 {

   ZmqMsg peticion;
   socket.recv(peticion);
   string requestMessage = "";
   
   if(StringLen(peticion.getData())>0)
     {
      requestMessage = (string)peticion.getData();
      Print(requestMessage);
            
     }
   
   return requestMessage;
   
 }

//+------------------------------------------------------------------+
// Send New Order - Devuelve los tickets abiertos para las peticiones
//+------------------------------------------------------------------+
string SendNewOrder(string request)
{

   ushort u_sep = StringGetCharacter(",",0);                  
   string result[];              
   int id = 0;
   string date = "";
   string symbol = "";
   string action = "";
   double open_price = 0;
   double tp_scalping = 0;
   double tp_intraday = 0;
   double tp_swing = 0;
   double sl_price = 0;
   string channel = "";

   //--- Split the string to substrings
   int k=StringSplit(request,u_sep,result);
   
   if(k>0)
   {
      id = int(result[0]);
      date = result[1];
      symbol = result[2];
      action = result[3];
      open_price = NormalizeDouble(double(result[4]),Digits);
      tp_scalping = NormalizeDouble(double(result[5]),Digits);
      tp_intraday = NormalizeDouble(double(result[6]),Digits);
      tp_swing = NormalizeDouble(double(result[7]),Digits);
      sl_price = NormalizeDouble(double(result[8]),Digits); 
      channel = result[9];
   }
   
   string tickets="";
   int ticket=0;
   
   if(Take_Profit == 1)
   {
      if(tp_scalping > 0)
         ticket = OpenNewOrder(symbol, action, sl_price, tp_scalping, id, channel);
         tickets = tickets + (string)ticket;
   }
   
   if(Take_Profit == 2)
   {
      if(tp_scalping > 0)
      {
         ticket = OpenNewOrder(symbol, action, sl_price, tp_scalping, id, channel);
         tickets = tickets + (string)ticket + ";";
      }
         
      if(tp_intraday > 0)
      {
         ticket = OpenNewOrder(symbol, action, sl_price, tp_intraday, id, channel);
         tickets = tickets + (string)ticket;
      }
   }
   
   if(Take_Profit == 3)
   {
   
      if(tp_scalping > 0)
      {
         ticket = OpenNewOrder(symbol, action, sl_price, tp_scalping, id, channel);
         tickets = tickets + (string)ticket + ";";
      }
         
      if(tp_intraday > 0)
      {
         ticket = OpenNewOrder(symbol, action, sl_price, tp_intraday, id, channel);
         tickets = tickets + (string)ticket + ";";
      }
         
      if(tp_swing > 0)
      {
         ticket = OpenNewOrder(symbol, action, sl_price, tp_swing, id, channel);
         tickets = tickets + (string)ticket;
      }
      
   }
        
   
   if(action == "CLOSE")
   {
     //Buscar las operaciones abiertas del ID 
     CloseOpenOrders(id);
     
   }

   return tickets;
}

//+-----------------------------------------------------------------------------------------+
// Open New Order
//+-----------------------------------------------------------------------------------------+
int OpenNewOrder(string symbol, string action, double sl, double tp, int id, string channel)
{

   int ticket = -1;
   
   if(action == "BUY")   
   {
   
      double dAsk = NormalizeDouble(MarketInfo(symbol, MODE_ASK),5);      
      double lots = CalculateLotSize(sl, symbol, OP_BUY);
              
      ticket=OrderSend(symbol,OP_BUY,lots,dAsk,Slippage,sl, tp,channel,id,0,Green);
   
      if(ticket>0)
      {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
          Print("BUY order opened : ",OrderOpenPrice());
      }
      else
          Print("Error opening BUY order : ",Err_Msg(GetLastError()));
            
   }
   
   if(action == "SELL")
   {
  
      double dBid = NormalizeDouble(MarketInfo(symbol, MODE_BID),5);   
      double lots = CalculateLotSize(sl, symbol, OP_SELL);
      
      ticket=OrderSend(symbol,OP_SELL,lots,dBid,Slippage,sl,tp,channel,id,0,Red);
   
      if(ticket>0)
      {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
          Print("SELL order opened : ",OrderOpenPrice());
      }
      else
          Print("Error opening SELL order : ",Err_Msg(GetLastError()));
            
   }
   
   return ticket;

}

//+------------------------------------------------------------------+
// Close the orden for a given magic number
//+------------------------------------------------------------------+

int CloseOpenOrders(int id){ 


    for( int i = 0 ; i < OrdersTotal() ; i++ ) { 

         OrderSelect( i, SELECT_BY_POS, MODE_TRADES ); 

         if (OrderMagicNumber() == id) 
         {
             RefreshRates();              
             return OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),5);
         }
               
    } 

    
    return 0; 
} 


//+------------------------------------------------------------------+
// Money Management function - Fix Lot
//+------------------------------------------------------------------+
double CalculateLotSize(double SL, string symbol, int action)
{          
   double lotSize = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double digits = MarketInfo(symbol, MODE_DIGITS);
   double tick_size =  MarketInfo(symbol, MODE_TICKSIZE);
   
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((digits == 3) || (digits == 5)){
      nTickValue = nTickValue * 10;
      tick_size = tick_size * 10;
   }
   
   
   if (MM_Type == 1)
      lotSize = Lots;
   
   if (MM_Type == 2)
   {
      // We apply the formula to calculate the position size and assign the value to the variable.
      // StopLoss in PIPS
      double stoploss= 0;
      
      if(action == OP_BUY)
      {
         double dAsk = NormalizeDouble(MarketInfo(symbol, MODE_ASK),5);
         stoploss = int((dAsk - SL) / tick_size);
      }
      else
      { 
         double dBid = NormalizeDouble(MarketInfo(symbol, MODE_BID),5);
         stoploss = int((SL - dBid) / tick_size);
      }
      
      
      lotSize = (AccountBalance() * MaxRiskPerTrade / 100) / (stoploss * nTickValue);
      lotSize = MathRound(lotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   }
   
   return lotSize;
}


//+------------------------------------------------------------------+
// Returns error message text for a given MQL4 error number
//+------------------------------------------------------------------+
string Err_Msg(int e)
{
  switch (e)   {
    case 0:     return("Error 0000:  No error returned.");
    case 1:     return("Error 0001:  No error returned, but the result is unknown.");
    case 2:     return("Error 0002:  Common error.");
    case 3:     return("Error 0003:  Invalid trade parameters.");
    case 4:     return("Error 0004:  Trade server is busy.");
    case 5:     return("Error 0005:  Old version of the client terminal.");
    case 6:     return("Error 0006:  No connection with trade server.");
    case 7:     return("Error 0007:  Not enough rights.");
    case 8:     return("Error 0008:  Too frequent requests.");
    case 9:     return("Error 0009:  Malfunctional trade operation.");
    case 64:    return("Error 0064:  Account disabled.");
    case 65:    return("Error 0065:  Invalid account.");
    case 128:   return("Error 0128:  Trade timeout.");
    case 129:   return("Error 0129:  Invalid price.");
    case 130:   return("Error 0130:  Invalid stops.");
    case 131:   return("Error 0131:  Invalid trade volume.");
    case 132:   return("Error 0132:  Market is closed.");
    case 133:   return("Error 0133:  Trade is disabled.");
    case 134:   return("Error 0134:  Not enough money.");
    case 135:   return("Error 0135:  Price changed.");
    case 136:   return("Error 0136:  Off quotes.");
    case 137:   return("Error 0137:  Broker is busy.");
    case 138:   return("Error 0138:  Requote.");
    case 139:   return("Error 0139:  Order is locked.");
    case 140:   return("Error 0140:  Long positions only allowed.");
    case 141:   return("Error 0141:  Too many requests.");
    case 145:   return("Error 0145:  Modification denied because order too close to market.");
    case 146:   return("Error 0146:  Trade context is busy.");
    case 147:   return("Error 0147:  Expirations are denied by broker.");
    case 148:   return("Error 0148:  The amount of open and pending orders has reached the limit set by the broker.");
    case 149:   return("Error 0149:  An attempt to open a position opposite to the existing one when hedging is disabled.");
    case 150:   return("Error 0150:  An attempt to close a position contravening the FIFO rule.");
    case 4000:  return("Error 4000:  No error.");
    case 4001:  return("Error 4001:  Wrong function pointer.");
    case 4002:  return("Error 4002:  Array index is out of range.");
    case 4003:  return("Error 4003:  No memory for function call stack.");
    case 4004:  return("Error 4004:  Recursive stack overflow.");
    case 4005:  return("Error 4005:  Not enough stack for parameter.");
    case 4006:  return("Error 4006:  No memory for parameter string.");
    case 4007:  return("Error 4007:  No memory for temp string.");
    case 4008:  return("Error 4008:  Not initialized string.");
    case 4009:  return("Error 4009:  Not initialized string in array.");
    case 4010:  return("Error 4010:  No memory for array string.");
    case 4011:  return("Error 4011:  Too long string.");
    case 4012:  return("Error 4012:  Remainder from zero divide.");
    case 4013:  return("Error 4013:  Zero divide.");
    case 4014:  return("Error 4014:  Unknown command.");
    case 4015:  return("Error 4015:  Wrong jump (never generated error).");
    case 4016:  return("Error 4016:  Not initialized array.");
    case 4017:  return("Error 4017:  DLL calls are not allowed.");
    case 4018:  return("Error 4018:  Cannot load library.");
    case 4019:  return("Error 4019:  Cannot call function.");
    case 4020:  return("Error 4020:  Expert function calls are not allowed.");
    case 4021:  return("Error 4021:  Not enough memory for temp string returned from function.");
    case 4022:  return("Error 4022:  System is busy (never generated error).");
    case 4050:  return("Error 4050:  Invalid function parameters count.");
    case 4051:  return("Error 4051:  Invalid function parameter value.");
    case 4052:  return("Error 4052:  String function internal error.");
    case 4053:  return("Error 4053:  Some array error.");
    case 4054:  return("Error 4054:  Incorrect series array using.");
    case 4055:  return("Error 4055:  Custom indicator error.");
    case 4056:  return("Error 4056:  Arrays are incompatible.");
    case 4057:  return("Error 4057:  Global variables processing error.");
    case 4058:  return("Error 4058:  Global variable not found.");
    case 4059:  return("Error 4059:  Function is not allowed in testing mode.");
    case 4060:  return("Error 4060:  Function is not confirmed.");
    case 4061:  return("Error 4061:  Send mail error.");
    case 4062:  return("Error 4062:  String parameter expected.");
    case 4063:  return("Error 4063:  Integer parameter expected.");
    case 4064:  return("Error 4064:  Double parameter expected.");
    case 4065:  return("Error 4065:  Array as parameter expected.");
    case 4066:  return("Error 4066:  Requested history data in updating state.");
    case 4067:  return("Error 4067:  Some error in trading function.");
    case 4099:  return("Error 4099:  End of file.");
    case 4100:  return("Error 4100:  Some file error.");
    case 4101:  return("Error 4101:  Wrong file name.");
    case 4102:  return("Error 4102:  Too many opened files.");
    case 4103:  return("Error 4103:  Cannot open file.");
    case 4104:  return("Error 4104:  Incompatible access to a file.");
    case 4105:  return("Error 4105:  No order selected.");
    case 4106:  return("Error 4106:  Unknown symbol.");
    case 4107:  return("Error 4107:  Invalid price.");
    case 4108:  return("Error 4108:  Invalid ticket.");
    case 4109:  return("Error 4109:  Trade is not allowed. Enable checkbox 'Allow live trading' in the expert properties.");
    case 4110:  return("Error 4110:  Longs are not allowed. Check the expert properties.");
    case 4111:  return("Error 4111:  Shorts are not allowed. Check the expert properties.");
    case 4200:  return("Error 4200:  Object exists already.");
    case 4201:  return("Error 4201:  Unknown object property.");
    case 4202:  return("Error 4202:  Object does not exist.");
    case 4203:  return("Error 4203:  Unknown object type.");
    case 4204:  return("Error 4204:  No object name.");
    case 4205:  return("Error 4205:  Object coordinates error.");
    case 4206:  return("Error 4206:  No specified subwindow.");
    case 4207:  return("Error 4207:  Some error in object function.");
  }   
  
  return("Error " + string(e) + ": ??? Unknown error.");
}

//+------------------------------------------------------------------+
// Draw information Box
//+------------------------------------------------------------------+

void SetText(string label, string text)
{   
    ObjectSetText(label,text,10,"Tahoma",clrAquamarine);
}

void CreateLabels()
{
      
    clear(label_name);
    
    long marginLeft = 50; // left justify for dynamic window size
    string name="info_box_socket";
      
    if(ObjectFind(name)==-1)
        ObjectCreate(name,OBJ_LABEL,0,0,0);
            
    ObjectSet(name,OBJPROP_XDISTANCE,marginLeft);
    ObjectSet(name,OBJPROP_YDISTANCE,50);
    ObjectSet(name,OBJPROP_CORNER,0);
    ObjectSet(name,OBJPROP_BACK,false);
    
    name="info_box_status";
      
    if(ObjectFind(name)==-1)
        ObjectCreate(name,OBJ_LABEL,0,0,0);
            
    ObjectSet(name,OBJPROP_XDISTANCE,marginLeft);
    ObjectSet(name,OBJPROP_YDISTANCE,100);
    ObjectSet(name,OBJPROP_CORNER,0);
    ObjectSet(name,OBJPROP_BACK,false);
    
    name="info_box_orders";
      
    if(ObjectFind(name)==-1)
        ObjectCreate(name,OBJ_LABEL,0,0,0);
            
    ObjectSet(name,OBJPROP_XDISTANCE,marginLeft);
    ObjectSet(name,OBJPROP_YDISTANCE,150);
    ObjectSet(name,OBJPROP_CORNER,0);
    ObjectSet(name,OBJPROP_BACK,false);
    
    
}

void clear(string prefix) 
  {
   string name;
   int obj_total=ObjectsTotal();

   for(int i=obj_total-1; i>=0; i--)
     {
      name=ObjectName(i);
      if(StringFind(name,prefix)==0)
         ObjectDelete(name);
     }
  }  
