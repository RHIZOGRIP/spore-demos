// Generic deterministic full-future beam planner. See README.md for protocol.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <unordered_set>
#include <vector>
using namespace std;
struct Config {double stone,grain,hp,gift_stone,gift_grain,gift_gold,loss,quarry,fields,repair_cost,repair,trade,wear,pressure,cascade;} c;
struct Tide {double height,strike,debt_damage; int storm,offer,debt_section;};
struct State {double stone=0,grain=0,gold=0; array<double,3> hp{}; int workers=9, flooded=0, debts=0;};
struct Action {int q=0,f=0,d=0,gate=0,bargain=0,hires=0;};
struct Node {State s; Action a; int parent=-1; array<double,7> score{};};
vector<Tide> ts;
int pop(int m){return __builtin_popcount((unsigned)m);}
State step(State s,Action a,int t){
 s.gold-=5*a.hires; s.workers+=a.hires;
 if(a.bargain && ts[t].offer){s.stone+=c.gift_stone;s.grain+=c.gift_grain;s.gold+=c.gift_gold;s.debts|=1<<t;}
 double productivity=1.0-pop(s.flooded)*c.loss;
 s.stone+=a.q*c.quarry*productivity; s.grain+=a.f*c.fields*productivity;
 for(int j=0;j<a.d;j++) {int k=-1;for(int i=0;i<3;i++)if(!(s.flooded>>i&1)&&(k<0||s.hp[i]<s.hp[k]))k=i;
  if(k>=0&&s.stone>=c.repair_cost){double needed=min(c.repair,100.0-s.hp[k]);if(needed>0){s.stone-=c.repair_cost*(needed/c.repair);s.hp[k]+=needed;}}}
 if(t>=2&&(s.debts>>(t-2)&1)){auto d=ts[t-2];if(!(s.flooded>>d.debt_section&1))s.hp[d.debt_section]-=d.debt_damage;s.debts&=~(1<<(t-2));}
 if(a.gate){s.gold+=c.trade;if(ts[t].height>=4){for(int i=0;i<3;i++)if(!(s.flooded>>i&1)){s.flooded|=1<<i;s.hp[i]=0;break;}}}
 for(int i=0;i<3;i++)if(!(s.flooded>>i&1)){double hit=c.wear+ts[t].height*c.pressure+pop(s.flooded)*c.cascade;if(ts[t].storm==i)hit+=ts[t].strike;s.hp[i]-=hit;if(s.hp[i]<=0){s.flooded|=1<<i;s.hp[i]=0;}}
 int missing=max(0,s.workers-(int)floor(s.grain));s.grain=max(0.0,s.grain-s.workers);s.workers-=missing;return s;
}
array<double,7> evaluate(const State&s,int next){
 int dry=3-pop(s.flooded); double sum=0,mn=100,mx=0,threat=0;
 for(int i=0;i<3;i++)if(!(s.flooded>>i&1)){
  sum+=s.hp[i];mn=min(mn,s.hp[i]);mx=max(mx,s.hp[i]);
  if(next<12){double hit=c.wear+ts[next].height*c.pressure+pop(s.flooded)*c.cascade+(ts[next].storm==i?ts[next].strike:0);
   if(next>=2&&(s.debts>>(next-2)&1)&&ts[next-2].debt_section==i)hit+=ts[next-2].debt_damage;
   threat+=max(0.0,hit+10-s.hp[i]);}}
 double remaining=12-next, prod=1-pop(s.flooded)*c.loss;
 double stone=min(s.stone,remaining*max(1,s.workers)*c.repair_cost+8),food=min(s.grain,remaining*max(1,s.workers)+4);
 double econ=stone*1.7+food*2+min(s.gold,5.0*(12-s.workers))*0.7;
 double labor=s.workers*(12+min(remaining,5.0)*2)*max(0.3,prod);
 double debt=0;for(int t=max(0,next-2);t<next;t++)if((s.debts>>t&1)&&!(s.flooded>>ts[t].debt_section&1))debt+=ts[t].debt_damage;
 double base=sum+dry*100+labor+econ-debt*.55-threat*1.2;
 return {base,base+sum*.7+mn*1.7-econ*.4,base+econ*1.4,base+labor*1.8,base+dry*130+mn*.7,base+mx*2.8-dry*65,base+mn*2.2-threat*2};
}
// Exact binary state identity: no resource quantization and no approximate merging.
struct Key {array<uint64_t,6> x; int w,f,d; bool operator==(const Key&o)const{return x==o.x&&w==o.w&&f==o.f&&d==o.d;}};
struct Hash {size_t operator()(const Key&k)const{uint64_t h=0x9e3779b97f4a7c15ULL;for(auto x:k.x){x^=x>>30;x*=0xbf58476d1ce4e5b9ULL;x^=x>>27;h^=x+(h<<6)+(h>>2);}return h^k.w^(k.f<<8)^(k.d<<12);}};
Key key(const State&s){Key k;double a[]={s.stone,s.grain,s.gold,s.hp[0],s.hp[1],s.hp[2]};for(int i=0;i<6;i++){if(a[i]==0)a[i]=0;memcpy(&k.x[i],&a[i],8);}k.w=s.workers;k.f=s.flooded;k.d=s.debts;return k;}
void stateout(const State&s){cout<<"{\"stone\":"<<s.stone<<",\"grain\":"<<s.grain<<",\"gold\":"<<s.gold<<",\"workers\":"<<s.workers<<",\"hp\":["<<s.hp[0]<<","<<s.hp[1]<<","<<s.hp[2]<<"],\"flooded\":[";for(int i=0;i<3;i++)cout<<(i?",":"")<<((s.flooded>>i&1)?"true":"false");cout<<"]}";}
int main(){ios::sync_with_stdio(false);cin.tie(nullptr);cout<<setprecision(17);
 int width,count,idle;if(!(cin>>width>>count>>idle))return 2;
 cin>>c.stone>>c.grain>>c.hp>>c.gift_stone>>c.gift_grain>>c.gift_gold>>c.loss>>c.quarry>>c.fields>>c.repair_cost>>c.repair>>c.trade>>c.wear>>c.pressure>>c.cascade;
 cout<<"{\"results\":[";
 for(int run=0;run<count;run++){long long seed;cin>>seed;ts.resize(12);for(auto&t:ts)cin>>t.height>>t.storm>>t.strike>>t.offer>>t.debt_section>>t.debt_damage;
 State initial;initial.stone=c.stone;initial.grain=c.grain;initial.hp.fill(c.hp);
 vector<vector<Node>> layers(1,vector<Node>(1));layers[0][0].s=initial;
 uint64_t expanded=0,unique=0,duplicates=0;vector<uint64_t> byturn;int endDepth=0,endIndex=0;bool won=false;Node loss;bool haveLoss=false;int lossDepth=0;
 for(int t=0;t<12;t++){
  vector<Node> cand;unordered_set<Key,Hash> seen;uint64_t before=expanded;bool anyWin=false;
  auto &beam=layers.back();
  for(int p=0;p<(int)beam.size();p++){const State&s=beam[p].s;
   int maxhire=min(12-s.workers,(int)floor(s.gold/5));
   for(int h=0;h<=maxhire;h++){int w=s.workers+h;
    for(int q=0;q<=w&&!anyWin;q++)for(int f=0;f<=w-q&&!anyWin;f++)for(int d=(idle?0:w-q-f);d<=w-q-f&&!anyWin;d++)
    for(int b=0;b<=(ts[t].offer?1:0)&&!anyWin;b++)for(int g=0;g<2&&!anyWin;g++){
     Action a{q,f,d,g,b,h};State v=step(s,a,t);expanded++;
     Node n;n.s=v;n.a=a;n.parent=p;n.score=evaluate(v,t+1);
     if(v.flooded==7){if(!haveLoss||t+1>lossDepth||(t+1==lossDepth&&n.score[0]>loss.score[0])){loss=n;haveLoss=true;lossDepth=t+1;}continue;}
     if(t==11){cand.clear();cand.push_back(n);anyWin=true;break;}
     if(!seen.insert(key(v)).second){duplicates++;continue;}cand.push_back(n);unique++;
    }
    if(anyWin)break;
   }if(anyWin)break;
  }
  byturn.push_back(expanded-before);
  if(cand.empty()){endDepth=lossDepth;break;}
  if(anyWin){layers.push_back(move(cand));endDepth=12;endIndex=0;won=true;break;}
  if((int)cand.size()<=width)layers.push_back(move(cand));
  else{
   vector<int> selected,indices(cand.size());vector<char> used(cand.size(),0);iota(indices.begin(),indices.end(),0);
   auto pick=[&](vector<int>&v,int quota,int mode){int k=min(quota,(int)v.size());auto cmp=[&](int a,int b){double x=cand[a].score[mode],y=cand[b].score[mode];return x!=y?x>y:a<b;};if(k<(int)v.size())nth_element(v.begin(),v.begin()+k,v.end(),cmp);sort(v.begin(),v.begin()+k,cmp);for(int j=0;j<k;j++)if(!used[v[j]]){used[v[j]]=1;selected.push_back(v[j]);}};
   // Seven economic/survival rankings, plus explicit coverage of each flood pattern.
   int quota=max(1,width*2/3/7);for(int mode=0;mode<7;mode++)pick(indices,quota,mode);
   int bucketquota=max(1,width/3/7);for(int mask=0;mask<7;mask++){vector<int> bucket;for(int i=0;i<(int)cand.size();i++)if(cand[i].s.flooded==mask)bucket.push_back(i);pick(bucket,bucketquota,0);}
   sort(indices.begin(),indices.end(),[&](int a,int b){return cand[a].score[0]!=cand[b].score[0]?cand[a].score[0]>cand[b].score[0]:a<b;});
   for(int i:indices){if((int)selected.size()<width&&!used[i]){used[i]=1;selected.push_back(i);}}
   if((int)selected.size()>width)selected.resize(width);
   vector<Node> next;for(int i:selected)next.push_back(cand[i]);layers.push_back(move(next));
  }
  endDepth=t+1;endIndex=0;for(int i=1;i<(int)layers.back().size();i++)if(layers.back()[i].score[0]>layers.back()[endIndex].score[0])endIndex=i;
 }
 vector<Node> path;
 if(!won&&lossDepth==endDepth&&endDepth==(int)layers.size()){path.push_back(loss);endIndex=loss.parent;for(int t=endDepth-1;t>0;t--){path.push_back(layers[t][endIndex]);endIndex=path.back().parent;}}
 else for(int t=endDepth;t>0;t--){path.push_back(layers[t][endIndex]);endIndex=path.back().parent;}
 reverse(path.begin(),path.end());
 if(run){cout<<",";}
 cout<<"{\"seed\":"<<seed<<",\"won\":"<<(won?"true":"false")<<",\"actions\":[";
 for(size_t i=0;i<path.size();i++){auto a=path[i].a;if(i)cout<<",";cout<<"{\"jobs\":["<<a.q<<","<<a.f<<","<<a.d<<"],\"gate\":"<<(a.gate?"true":"false")<<",\"bargain\":"<<(a.bargain?"true":"false")<<",\"hires\":"<<a.hires<<"}";}
 cout<<"],\"states\":[";for(size_t i=0;i<path.size();i++){if(i)cout<<",";stateout(path[i].s);}cout<<"],\"diagnostics\":{\"expansions\":"<<expanded<<",\"unique_live_candidates\":"<<unique<<",\"exact_duplicates\":"<<duplicates<<",\"reached_tide\":"<<path.size()<<",\"expansions_by_tide\":[";for(size_t i=0;i<byturn.size();i++)cout<<(i?",":"")<<byturn[i];cout<<"],\"failure_is_not_impossibility\":true}}";
 }
 cout<<"]}\n";return cin.fail()?3:0;
}
