//+------------------------------------------------------------------+
//|              ArtificialIntelligence(Carlos Bergasmo (V@).mq5     |
//|                               Copyright © 2022, Carlos Bergamo   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Yury V. Reshetov ICQ:282715499  http://reshetov.xnet.uz/"
#property link      "http://reshetov.xnet.uz/"
#property version   "1.001"
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
CAccountInfo   m_account;                    // account info wrapper
CSymbolInfo    m_symbol;                     // symbol info object
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
//---- input parameters
input int    x1 = 25;
input int    x2 = 50;
input int    x3 = 75;
input int    x4 = 100;
input int    x5 = 25;
input int    x6 = 50;
input int    x7 = 75;
input int    x8 = 100;
input ushort m_sl=4000;                      // stop loss level
input double m_lots=1.0;                     // volume transaction
input ulong  MagicNumber=788;                // magic number
//---
static datetime  prevtime=0;
int         handle_iAC;                      // variable for storing the handle of the iAC indicator
int         handle_iADX;
int         handle_iRandom;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(m_lots<=0.0)
     {
      Print("The \"volume transaction\" can't be smaller or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
   m_symbol.Name(Symbol());                        // sets symbol name
   m_trade.SetExpertMagicNumber(MagicNumber);      // sets magic number
   m_trade.SetDeviationInPoints(0);               // sets deviation

//--- create handle of the indicator iAC
   handle_iAC=iAC(Symbol(),Period());
   handle_iADX=iADX(Symbol(),Period(),1);
//--- if the handle is not created
   if(handle_iAC==INVALID_HANDLE)
      if(handle_iADX==INVALID_HANDLE)
        {
         //--- tell about the failure and output the error code
         PrintFormat("Failed to create handle of the iAC indicator for the symbol %s/%s, error code %d",
                     Symbol(),
                     EnumToString(Period()),
                     GetLastError());
         //--- the indicator is stopped early
         return(INIT_FAILED);
        }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(iTime(m_symbol.Name(),Period(),0)==prevtime)
      return;
   prevtime=iTime(m_symbol.Name(),Period(),0);
   int spread=10; //Variavel propagação
//----
   if(IsTradeAllowed()) //É permitido comércio
     {
      if(RefreshRates()) //Taxas de atualização 
         spread=m_symbol.Spread(); //propagação 
      else
         return;
     }
   else
     {
      prevtime=0; //tempo anterior 
      return;
     }
   ulong  m_ticket=0; //ulong = (você deseja)... 
//--- check for opened position (verificar a posição aberta)
   int total=PositionsTotal();
//----
   for(int i=total-1; i>=0; i--)
     {
      if(!m_position.SelectByIndex(i))
         return;
      //--- check for symbol & magic number (verifique se há símbolo e número mágico)
      if(m_position.Symbol()==Symbol() && m_position.Magic()==MagicNumber)
        {
         ulong m_prevticket=m_position.Ticket();
         //--- long position is opened (posição longa está aberta)
         if(m_position.PositionType()==POSITION_TYPE_BUY)
           {
            
            //--- check profit
            if(m_symbol.Bid()>(m_position.StopLoss()+(m_sl*2+spread)*Point()))
              {
               if(perceptron()<0)
                 {
                  //--- reverse
                  if(m_trade.Sell(m_lots*2,Symbol(),m_symbol.Bid(),m_symbol.Ask()+m_sl*Point(),0.0,"Roseta"))
                    {
                     m_ticket=m_trade.ResultDeal();
                    }
                  Sleep(30000);
                  //---
                  if(m_ticket==0)
                     prevtime=0;
                  else
                    {
                     m_trade.PositionCloseBy(m_ticket,m_prevticket);
                     return;
                    }
                 }
               else
                 {
                  //--- trailing stop
                  if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.Bid()-m_sl*(Point()*0.618),0))
                    {
                     Sleep(30000);
                     prevtime=0;
                    }
                 }
              }
            //--- short position is opened
           }
         else
           {
            // check profit
            if(m_symbol.Ask()<(m_position.StopLoss()-(m_sl*2+spread)*Point()))
              {
               if(perceptron()>0)
                 {
                  //--- reverse
                  if(m_trade.Buy(m_lots*2,Symbol(),m_symbol.Ask(),m_symbol.Bid()-m_sl*Point(),0.0,"Roseta Puchada"))
                    {
                     m_ticket=m_trade.ResultDeal();
                    }
                  Sleep(30000);
                  //---
                  if(m_ticket==0)
                     prevtime=0;
                  else
                    {
                     m_trade.PositionCloseBy(m_ticket,m_prevticket);
                     return;
                    }
                 }
               else
                 {
                  //--- trailing stop
                  if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.Ask()+m_sl*(Point()*0.618),0))
                    {
                     Sleep(30000);
                     prevtime=0;
                    }
                 }
              }
           }
         //--- exit
         return;
        }
     }
//--- check for long or short position possibility
   if(perceptron()>0)
     {
      //--- long
      if(m_trade.Buy(m_lots,Symbol(),m_symbol.Ask(),m_symbol.Ask()-m_sl*Point(),0.0,"Roseta Batida"))
        {
         m_ticket=m_trade.ResultDeal();
        }
      //---
      if(m_ticket==0)
        {
         Sleep(30000);
         prevtime=0;
        }
     }
   else
     {
      //--- short
      if(m_trade.Sell(m_lots,Symbol(),m_symbol.Bid(),m_symbol.Bid()+m_sl*Point(),0.0,"Cutuca Boiadeiro"))
        {
         m_ticket=m_trade.ResultDeal();
        }
      if(m_ticket==0)
        {
         Sleep(30000);
         prevtime=0;
        }
     }
//--- exit
   return;
  }
//+------------------------------------------------------------------+
//| The PERCEPTRON - a perceiving and recognizing function           |
//+------------------------------------------------------------------+
double perceptron()
  {
   double ww1 = x1;
   double ww2 = x2;
   double ww3 = x3;
   double ww4 = x4;
   double ww5 = x5;
   double ww6 = x6;
   double ww7 = x7;
   double ww8 = x8;
   double wa1 = iACGet(2);
   double wa2 = iACGet(7);
   double wa3 = iACGet(21);
   double wa4 = iACGet(100);
   double wa5 = iADXGet(2);
   double wa6 = iADXGet(7);
   double wa7 = iADXGet(21);
   double wa8 = iADXGet(100);
//Proporcao Aurea
   double w1 = (ww1 * 0.618);
   double w2 = (ww2 * 0.618);
   double w3 = (ww3 * 0.618);
   double w4 = (ww4 * 0.618);
   double w5 = (ww5 * 0.618);
   double w6 = (ww6 * 0.618);
   double w7 = (ww7 * 0.618);
   double w8 = (ww8 * 0.618);
   double a1 = (wa1 * 0.618);
   double a2 = (wa1 * 0.618);
   double a3 = (wa1 * 0.618);
   double a4 = (wa1 * 0.618);
   double a5 = (wa1 * 0.618);
   double a6 = (wa1 * 0.618);
   double a7 = (wa1 * 0.618);
   double a8 = (wa1 * 0.618);
//Fim proporcao aqurea
   double mult1 = ((w1*a1)*1.618);
   double mult2 = ((w2*a2)*1.618);
   double mult3 = ((w3*a3)*1.618);
   double mult4 = ((w4*a4)*1.618);
   double mult5 = ((w5*a5)*1.618);
   double mult6 = ((w6*a6)*1.618);
   double mult7 = ((w7*a7)*1.618);
   double mult8 = ((w8*a8)*1.618);
   // Bias
   double bias = 0.618;
   // Taxa aprendizagem
   double tx=0.5;   

   return(((mult1+mult2+mult3+mult4+mult5+mult6+mult7+mult8) +tx) * bias);
  }
//+------------------------------------------------------------------+
//| Gets the information about permission to trade                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert("Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert("Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   else
     {
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         Alert("Automated trading is forbidden in the program settings for ",__FILE__);
         return(false);
        }
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
     {
      Alert("Automated trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
            " at the trade server side");
      return(false);
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      Comment("Trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
              ".\n Perhaps an investor password has been used to connect to the trading account.",
              "\n Check the terminal journal for the following entry:",
              "\n\'",AccountInfoInteger(ACCOUNT_LOGIN),"\': trading has been disabled - investor mode.");
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iAC                                |
//+------------------------------------------------------------------+
double iACGet(const int index)
  {
   double AC[];
   ArraySetAsSeries(AC,true);
//--- reset error code
   ResetLastError();
//--- fill a part of the iACBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iAC,0,0,index+1,AC)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iAC indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(AC[index]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iADXGet(const int index)
  {
   double ADX[];
   ArraySetAsSeries(ADX,true);
//--- reset error code
   ResetLastError();
//--- fill a part of the iACBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iADX,0,0,index+1,ADX)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iAC indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(ADX[index]);
  }
//+------------------------------------------------------------------+
