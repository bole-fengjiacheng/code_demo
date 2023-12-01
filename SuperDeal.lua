local superDealPath = "super_deal"
local resVersion = "2023-12-01"

local MaxBuyCount = 3

local EVENT_ID = 1049
local VERSION = "1.02"

local function addSpine(parent, file, aniName, loop, pos, completeCallback)
    aniName = aniName or "animation"
    if loop == false then
        loop = false
    else
        loop = true
    end
    pos = pos or bole.getNodeCenterPos(parent)
    local path = superDealPath .. "/spine/" .. file .. "/spine"
    local _, spine = bole.addSpineAnimation(parent, 0, path, pos, aniName, completeCallback, nil, nil, loop, loop)
    return spine
end

local MUSIC_PATH = superDealPath .. "/audio/"
local playAudio = function (name, loop, isPlay)
    if isPlay == false then
        bole.stopMusic(name, MUSIC_PATH)
    else
        bole.playMusic(name, nil, loop, MUSIC_PATH)
    end
end

local SuperDealDoneDialog = class("SuperDealDoneDialog", CCSNode)
local SuperDealMainDialog = class("SuperDealMainDialog" , CCSNode)

SuperDeal = ActivityBase_v2:newActivity("SuperDeal")
SuperDeal._updateReceiver = ActivityUpdateReceiver.new(EVENT_ID,function (  )
    SuperDeal.isReady()
end)

function SuperDeal:ctor()
    self.super.ctor(self)
    self:initData()
end

function SuperDeal:isReady()
    local isReady = bole.getResVerion(superDealPath .. "/zzz") == resVersion
    if not isReady then
        bole.downloadZip(superDealPath , "res/" .. superDealPath)
    end

    return isReady
end

function SuperDeal:isAvailable()
    log.d("is SuperDeal available?", self:isReady(), self:getLeftTime())
    return self:isReady() and self:getLeftTime() > 0
end

function SuperDeal:onInit(data) --> = onLogin
    if data[EVENT_ID] and next(data[EVENT_ID].params) then
        local actData = data[EVENT_ID].params and data[EVENT_ID].params.super_deal
        self:isReady()
        self:updateData(actData)
    end
end

function SuperDeal:initData()
    self._activeCount = 0
    self.endTime = os.time()
    self._curChanceIsUsed = false
end

function SuperDeal:isBuyMax()
    return self._activeCount == MaxBuyCount and self._curChanceIsUsed
end

function SuperDeal:isCanBuy()
    return not self._curChanceIsUsed
end

function SuperDeal:getActiveCount()
    return self._activeCount
end

function SuperDeal:isServerOpen(data)
    for i,v in pairs(data) do
        if i == EVENT_ID and v.version == VERSION then
            log.d("SuperDeal is open")
            return true
        end
    end
    return false
end

function SuperDeal:getLeftTime()
    local leftTime = self.endTime - os.time()
    return leftTime > 0 and leftTime or 0
end

function SuperDeal:updateData(data)
    if data.activate then
        self._curChanceIsUsed = data.activate == 0
    end

    if data.count then
        self._activeCount = data.count
    end

    if data.left then
        self.endTime = data.left + os.time()
    end

    log.d("SuperDeal Data is update", self._curChanceIsUsed, self._activeCount, self.endTime)
end

function SuperDeal:onPaySuc(buyTag, data)
    log.d("SuperDeal buy check ", data.super_deal)
    if data.super_deal then
        self:updateData(data.super_deal)
    end
end

function SuperDeal:setUI(ui)
    self._mainUI = ui
end

function SuperDeal:removeUI()
    self._mainUI = nil
end

function SuperDeal:showMainDialog(callback)
    if self:isAvailable() and not bole.isValidNode(self._mainUI) then
        local dialog
        if self:isBuyMax() then
            dialog = SuperDealDoneDialog.new(callback)
        else
            dialog = SuperDealMainDialog.new(callback)
        end
        dialog:show()
    else
        _= callback and callback()
    end
end

---------------------------------
---SuperDealMainDialog 
---------------------------------
local getSuperDealIns = function ()
    return ActivityControl_v2:getInstance():getActivityIns("SuperDeal")
end

local function addSpine(parent, file, aniName, loop, pos, completeCallback, retain)
    aniName = aniName or "animation"
    loop = not (loop == false) -- nil=true
    if retain == nil then
        retain = loop
    end
  
    pos = pos or bole.getNodeCenterPos(parent)
    local path = superDealPath .. "/spine/" .. file .. "/spine"
    local _, spine = bole.addSpineAnimation(parent, 0, path, pos, aniName, completeCallback, nil, nil, retain, loop)
    return spine
end

function SuperDealMainDialog:ctor(callback)
    self.callback = callback
    
    self:initData()
    self.super.ctor(self , superDealPath.."/csd/Node_zhujiemian.csb")
    bole.addFreeMemListener(self, superDealPath)

    getSuperDealIns():setUI(self)
    local function onexit(event)
        if event == "exit" then
            _ = getSuperDealIns() and getSuperDealIns():removeUI()
        end
    end
    self:registerScriptHandler(onexit)
end

function SuperDealMainDialog:initData()
    self._selectIndex = 0
    self._rewardIcons = {}
end

function SuperDealMainDialog:enableBtns(enable)
    self.btnClose:setTouchEnabled(enable)
    self.btnBuy:setTouchEnabled(enable)
    self.btnPerk:setTouchEnabled(enable)

    for index = 1, 3 do
        self._rewardIcons[index]:setTouchEnabled(enable)
    end
end

function SuperDealMainDialog:selectReward(index)
    if self._selectIndex == index then
        return
    end

    for i = 1, 3 do
        local rewardRoot = self.root:getChildByName("Node_" .. i)
        local sign = rewardRoot:getChildByName("shuming")
        sign:setVisible(index == i)
        local icon = rewardRoot:getChildByName("jiangli")
        if index == i then
            icon:setColor(cc.c3b(255, 255, 255))
            -- icon._selectSpine = addSpine(icon, "reward_special_effect", "loop"):setLocalZOrder(-1)
            -- addSpine(icon, "reward_special_effect", "appear_up",false)
            icon._selectSpine = addSpine(icon, "reward_special_effect", "guang"):setLocalZOrder(-1)
            addSpine(icon, "reward_special_effect", "jingli_tanchu_up",false)
            if index ~= 1 then
                bole.fixPos(icon._selectSpine, -32)
            end
            if index == 3 then
                bole.fixPos(icon._selectSpine, -30)
            end
        else
            icon:setColor(cc.c3b(120, 120, 120))
            _ = bole.isValidNode(icon._selectSpine) and icon._selectSpine:removeFromParent()
        end
    end
    self:runTimeLine(120, 135, false)

    self._selectIndex = index
    self.btnBuy:active()
end

function SuperDealMainDialog:loadControls()
    self.timeLine = cc.CSLoader:createTimeline(self.csb)
    self.node:runAction(self.timeLine)

    self.root = self.node:getChildByName("root")

    local shadow = self.root:getChildByName("bij_5")
    bole.closeNodeCoverAttr(shadow)

    self.btnClose = self.root:getChildByName("btn_close")
    self:addTouchEvent(self.btnClose, function ()
        bole.playMusic("game2")
        self:hide()
    end)

    self.btnPerk = self.root:getChildByName("btn_")
    self:addTouchEvent(self.btnPerk, function ()
        bole.playMusic("game2")
        PurchasebenefitsControl:getInstance():showBenefitsPromotion(0.99, true, {"BYD","CHECKWIN"})
    end)

    self.btnBuy  = self.root:getChildByName("btn_buy")
    local buyLabel = self.btnBuy:getChildByName("LABEL")
    local price = PurchaseControl:getInstance():getLocalPrice(0.99)
    price = price or "$0.99"
    buyLabel:setString(price)
    self.btnBuy:setColor(cc.c3b(100, 100, 100))
    self.btnBuy:setTouchEnabled(false)
    function self.btnBuy:active()
        self:setColor(cc.c3b(255, 255, 255))
        self:setTouchEnabled(true)
    end

    bole.addBtnClickEvent(self.btnBuy, function ()
        bole.playMusic("game2")
        self:buy(self._selectIndex, function ()
            if bole.isValidNode(self) then
                self:hide()
            end
        end)
    end,{
        down = function()
            buyLabel:setColor(cc.c3b(100, 100, 100))
        end,
        up = function()
            buyLabel:setColor(cc.c3b(255, 255, 255))
        end,
    })

    self.lblProgress = self.root:getChildByName("of"):getChildByName("lbl")
    self.lblProgress:setString(getSuperDealIns():getActiveCount())

    for index = 1, 3 do
        local rewardRoot = self.root:getChildByName("Node_" .. index)
        self._rewardIcons[index] = rewardRoot:getChildByName("jiangli")
        bole.addClickEventNew(self._rewardIcons[index], function ()
            if self._selectIndex == 0 then
                self._guideSpines:stop()
            end
            playAudio("pick_sound")
            self:selectReward(index)
        end)
    end

    local timeBoard = self.root:getChildByName("daojishi")
    local lblLeftTime = timeBoard:getChildByName("lbl")
    bole.configCountDownLabel(lblLeftTime,
    function()
        return getSuperDealIns():getLeftTime()
    end,function ()
        lblLeftTime:stopAllActions()
        self:hide()
    end)

    local title = self.root:getChildByName("logo")
    addSpine(title, "title_effect")

    title:setBlendFunc(gl.ZERO, gl.ONE)

    self:startGuideSpine()
end

function SuperDealMainDialog:startGuideSpine()
    self._guideSpines = {
        removeSpines = function ()
            _ = bole.isValidNode(self._guideSpines[1]) and self._guideSpines[1]:removeFromParent()
            _ = bole.isValidNode(self._guideSpines[2]) and self._guideSpines[2]:removeFromParent()
        end,
        stop = function ()
            self.node:stopActionByTag(10010)
            self._guideSpines:removeSpines()
        end
    } 

    local lastIndex = -1
    local playAction = cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function ()
			self._guideSpines:removeSpines()
            local guideIndex = math.random(1, 3)
            while (guideIndex == lastIndex) do
                guideIndex = math.random(1, 3)  -- 保证本次随机数不和上一次重复
            end
            lastIndex = guideIndex
            local aniName = {"youpiao", "zuan", "xingxing"}
            local parent = self._rewardIcons[guideIndex]
            self._guideSpines[1] = addSpine(parent, "pick_hint_effect", aniName[guideIndex])
            self._guideSpines[2] = addSpine(parent, "hand_effect", nil, false, nil, nil, true):setScale(1/parent:getScale())
		end),
        cc.DelayTime:create(1.5)
	))
    playAction:setTag(10010)

    self.node:runAction(playAction)
end

function SuperDealMainDialog:buy(index, callback)
    if index then
        local payTag = "one_p_" .. index

        -- local vipRatio = bole.getVipRatioWithBoom()
        -- local levelRatio = bole.getCoinRatio()
        local price = 0.99
        local priceRaido = bole.getBaseCoinsByPrice(price)
        --local baseCoins = levelRatio * vipRatio * priceRaido
        local baseCoins = User:getInstance():getCoinsWithRatio(priceRaido , true)
        local item = PurchaseControl:getInstance():makePurchaseItem(baseCoins, price)
        PurchaseControl:getInstance():buy(item, callback, nil, nil, payTag)
    end
end

function SuperDealMainDialog:hide()
    self:enableBtns(false)
    bole.popExitWin(self, self, nil, true, self.callback)
end

function SuperDealMainDialog:runTimeLine( startFrame, endFrame, loop, speed )
	loop = loop or false
	if endFrame then
		self.timeLine:gotoFrameAndPlay(startFrame, endFrame, loop)
	else
		self.timeLine:gotoFrameAndPause(startFrame)
	end
	if speed then
		self.timeLine:setTimeSpeed(speed)
	end
end

function SuperDealMainDialog:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addChild(self, 2)
    bole.addMaskLayer(self)

    self:runTimeLine(0)
    bole.popWin(self, nil, nil, function ()
        self:runTimeLine(0, 90, false)
    end)
end



----------------------------------
--                              --
--    SuperDealRewardDialog     --
--                              --
----------------------------------
SuperDealRewardDialog = class("SuperDealRewardDialog", CCSNode)

function SuperDealRewardDialog:ctor(payData)
    self.rewardType = payData.super_deal_num or 1
    self.payData = payData

    local path = superDealPath.."/csd/node_huojiang.csb"
    self.super.ctor(self , path)
    self.action = cc.CSLoader:createTimeline(path)
    self.root:runAction(self.action)

    bole.addKeyboardEvent(self, function() end, false)
    bole.addFreeMemListener(self, superDealPath)
end

function SuperDealRewardDialog:setCallBack(callback)
    self.callback = callback
end

function SuperDealRewardDialog:loadControls()
    self.root = self.node:getChildByName("root")

    local shadow = self.root:getChildByName("bij_5")
    bole.closeNodeCoverAttr(shadow)

    local rewardRoot = self.root:getChildByName("jiangli")
    for i = 1, 3 do
        rewardRoot:getChildByName("jiangli_"..i):setVisible(i == self.rewardType)
    end

    local btnCollect = self.root:getChildByName("btn_collect")
    self:addTouchEvent(btnCollect, function()
        btnCollect:setTouchEnabled(false)

        if self.payData.reward_jades then
            local dealy = bole.flyJadesOnButton(btnCollect, self.payData.reward_jades)
            bole.laterCall(dealy,self,function ( )
                self:hide()
            end)
        else
            self:hide()
        end
    end)

    local title = self.root:getChildByName("jieshu_logo")
    addSpine(title, "reward_title_effect")
end

function SuperDealRewardDialog:playOpenSpine()
    local rewardIcon = self.root:getChildByName("jiangli"):getChildByName("jiangli_"..self.rewardType)
    local pos = bole.getNodeCenterPos(rewardIcon)
    -- if self.rewardType == 1 then
    --     pos = cc.pAdd(pos, cc.p(32,0))
    -- end
    -- addSpine(rewardIcon, "reward_special_effect", "appear_up", false, pos, function ()
    --     addSpine(rewardIcon, "reward_special_effect", "loop", true, pos):setLocalZOrder(-1)
    -- end)
    -- addSpine(rewardIcon, "reward_special_effect", "appear_down", false, pos):setLocalZOrder(-1)
    if self.rewardType ~= 1 then
        pos.x = pos.x - 32
    end
    if self.rewardType == 3 then
        pos.x = pos.x - 30
    end
    addSpine(rewardIcon, "reward_special_effect", "jingli_tanchu_up", false, pos, function ()
        addSpine(rewardIcon, "reward_special_effect", "guang", true, pos):setLocalZOrder(-1)
    end)
    addSpine(rewardIcon, "reward_special_effect", "jiangli_down", true, pos):setLocalZOrder(-1)
end

function SuperDealRewardDialog:hide()
    bole.popExitWin(self, self, nil, true, self.callback)
end

function SuperDealRewardDialog:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addChild(self, 3)
    bole.addMaskLayer(self)
    playAudio("award_sound")

    self.action:gotoFrameAndPause(0)
    bole.popWin(self, nil, nil, function ()
        self.action:gotoFrameAndPlay(0, 50, false)

        bole.laterCall(0.8, self, function()
            self.action:gotoFrameAndPlay(50, 150, true)
        end)
    end)

    bole.laterCall(0.8, self, function ()
        self:playOpenSpine()
    end)
end



---------------------------- 
--SuperDealDoneDialog 次数用尽
----------------------------
function SuperDealDoneDialog:ctor(callback)
    self.callback = callback
    self.super.ctor(self , superDealPath.."/csd/node_Finish.csb")
    bole.addFreeMemListener(self, superDealPath)
end

function SuperDealDoneDialog:loadControls()
    self.root = self.node:getChildByName("root")
    
    local btn_close = self.root:getChildByName("btn_close")
    self:addTouchEvent(btn_close, function ()
        bole.playMusic('game2')
        btn_close:setTouchEnabled(false)
        self:hide()
    end)

    bole.addKeyboardEvent(self, function()
        self:hide()
    end)
end

function SuperDealDoneDialog:hide()
    bole.popExitWin(self, self, nil, true, self.callback)
end

function SuperDealDoneDialog:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addChild(self, 2)
    bole.addMaskLayer(self, 0, 225)

    self:runTimeLine(0)
    bole.popWin(self, nil, nil, function ()
        self:runTimeLine(0, 30)
    end)
end