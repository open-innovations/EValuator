(function(root){

	if(!root.OI) root.OI = {};

	function Stepped(opt){
		if(!opt) opt = {};
		this.steps = [];
		var popup = document.getElementById('step');
		var _obj = this;
		if(!popup){
			popup = document.createElement('div');
			popup.setAttribute('id','step');
			popup.style.position = 'absolute';
			popup.style.background = opt.background||"black";
			popup.style.border = opt.border||"0px";
			popup.style.color = opt.color||"white";
			popup.style.padding = opt.padding||"1em";
			popup.style.zIndex = 1000;
			popup.style.transition = "all 0.3s ease-in";
			popup.style.display = "none";
			popup.style.cursor = "pointer";
			document.body.appendChild(popup);
			popup.addEventListener('click',function(){ _obj.close(); });
		}
		var active = -1;
		function Step(n,el,txt,placement){
			this.el = el;
			this.html = txt;
			this.placement = placement;
			this.active = false;
			if(!this.el){
				console.error('No DOM element to attach to.',el);
			}
			var styles = document.createElement('style');
			document.head.appendChild(styles);
			this.open = function(){
				active = n;
				if(this.el){
					var domRect = this.el.getBoundingClientRect();
					var x = domRect.x + domRect.width/2 + (window.pageXOffset || document.documentElement.scrollLeft);
					var y = domRect.y + domRect.height/2 + (window.pageYOffset || document.documentElement.scrollTop);
					var t = "";
					var m = "";
					var arrow = "";
					var off = "1.25em";
					switch (this.placement){
						case "left":
							x -= domRect.width/2;
							t = "translate3d(calc(-100% - "+off+"),-50%,0)";
							arrow = "left:100%;top:50%;transform:translate3d(0%,-50%,0);border-top: 1em solid transparent;border-bottom: 1em solid transparent;border-left: 1em solid "+(opt.background||"black")+";border-right:0;";
							break;
						case "right":
							x += domRect.width/2;
							t = "translate3d("+off+",-50%,0)";
							arrow = "left:0%;top:50%;transform:translate3d(-100%,-50%,0);border-top: 1em solid transparent;border-bottom: 1em solid transparent;border-right: 1em solid "+(opt.background||"black")+";";
							break;
						case "top":
							y -= domRect.height/2;
							t = "translate3d(-50%,calc(-100% - "+off+"),0)";
							arrow = "left:50%;top:99.99%;transform:translate3d(-50%,0%,0);border-left: 1em solid transparent;border-right: 1em solid transparent;border-top: 1em solid "+(opt.background||"black")+";border-bottom:0;";
							break;
						case "bottom":
							y += domRect.height/2;
							t = "translate3d(-50%,"+off+",0)";
							arrow = "left:50%;top:0%;transform:translate3d(-50%,-100%,0);border-left: 1em solid transparent;border-right: 1em solid transparent;border-bottom: 1em solid "+(opt.background||"black")+";border-top:0;";
							break;
					}
					if(typeof this.html==="text") popup.innerHTML = this.html;
					else if(typeof this.html==="function") popup.innerHTML = this.html.call(this,popup,txt);
					else popup.innerHTML = txt;

					popup.style.left = x+"px";
					popup.style.top = y+"px";
					popup.style.transform = t;
					popup.style.opacity = "1";
					popup.style.display = "";
					popup.setAttribute('data',n);
					styles.innerHTML = '#step *:last-child { margin-bottom: 0; max-width: 300px; } #step::before { content:""; position: absolute; width: 0em; height: 0em; '+arrow+' }';
					return this;
				}
				return this;
			}
			this.close = function(){
				if(active == n){
					popup.style.opacity = "0";
					active = -1;
				}
			}
			return this;
		}
		this.add = function(el,txt,placement){
			var s = new Step(this.steps.length,el,txt,placement);
			this.steps.push(s);
			return s;
		}
		this.close = function(n){
			if(popup){
				if(typeof n==="number" && n==active) this.steps[n].close();
				else if(typeof n!=="number") this.steps[active].close();
			}
		}

		return this;
	}
	
	root.OI.Stepped = function(){
		return new Stepped();
	};

})(window || this);