//+------------------------------------------------------------------+
//|                                                ea_mt4_server.mq4 |
//|                                                   RAUL LUCAS     |
//+------------------------------------------------------------------+
#property copyright "RAUL LUCAS"
#property version   "1.00"
#property description "Bot servidor para recibir peticiones desde python"
#property strict

#include <Zmq/Zmq.mqh>

input string TG_Channel = "EasyForexVip";
input int Socket_Port = 5000;
input int Take_Profit  =1;
input double Lots     =0.1;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Context context("mt4server");
Socket socket(context, ZMQ_REP);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   string input_socket = "tcp://127.0.0.1:" + string(Socket_Port);
   socket.connect(input_socket);
   //socket.connect("tcp://127.0.0.1:9999");
   Print("Socket address: ", input_socket);
   Print("Server connected: ",socket.valid());
   
   return(INIT_SUCCEEDED);
   
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //socket.disconnect("tcp://127.0.0.1:9999");
   
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   string requestedMessage = WaitForRequest();
   
   SendNewOrder(requestedMessage);
  
//---
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
      
      Sleep(1000);
      
      ZmqMsg mensaje("Request Processed: " + requestMessage);
      socket.send(mensaje);
      
     }
   
   return requestMessage;
   
 }
 
int SendNewOrder(string request)
{
   int slippage = 3;
   ushort u_sep = StringGetCharacter(",",0);                  
   string result[];              
   int id = 0;
   string date;
   string symbol;
   string action;
   double open_price = 0;
   double tp_scalping = 0;
   double tp_intraday = 0;
   double tp_swing = 0;
   double sl_price = 0;
   int ticket = 0;

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
   }    
   
   if(action == "BUY")
   {
        
      double tp_target = tp_scalping;
      
      switch(Take_Profit)
      {
         case 1:
            tp_target = tp_scalping;
            break;
         case 2:
            tp_target = tp_intraday;
            break;
         case 3:
            tp_target = tp_swing;
            break;
         default:
            tp_target = tp_scalping;
            break;
      }
      
      
      ticket=OrderSend(symbol,OP_BUY,Lots,Ask,slippage,sl_price, tp_target,TG_Channel,id,0,Green);
   
      if(ticket>0)
      {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
          Print("BUY order opened : ",OrderOpenPrice());
      }
      else
          Print("Error opening BUY order : ",GetLastError());
            
   }
   
   if(action == "SELL")
   {
      double tp_target = tp_scalping;
      
      switch(Take_Profit)
      {
         case 1:
            tp_target = tp_scalping;
            break;
         case 2:
            tp_target = tp_intraday;
            break;
         case 3:
            tp_target = tp_swing;
            break;
         default:
            tp_target = tp_scalping;
            break;
      }
  
      ticket=OrderSend(symbol,OP_SELL,Lots,Bid,slippage,sl_price,tp_target,TG_Channel,id,0,Red);
   
      if(ticket>0)
      {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
          Print("SELL order opened : ",OrderOpenPrice());
      }
      else
            Print("Error opening SELL order : ",GetLastError());
            
   }
   
   if(action == "CLOSE")
   {
     //Buscar las operaciones abiertas del ID 
     CloseOpenOrders(id);
     
   }

   return 0;
}


bool CloseOpenOrders(int id){ 

    // What we do is scan all orders and check if they are of the same symbol as the one where the EA is running.
    for( int i = 0 ; i < OrdersTotal() ; i++ ) { 
     // We select the order of index i selecting by position and from the pool of market/pending trades.
          OrderSelect( i, SELECT_BY_POS, MODE_TRADES ); 
                // If the pair of the order is equal to the pair where the EA is running.
           if (OrderMagicNumber() == id) 
           {
               RefreshRates(); 
               
               return OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),5);
           }
               
    } 
        // If the loop finishes it mean there were no open orders for that pair.
    
    return false; 
} 





