---------------------------------
---CouponLottery Control
---------------------------------
local CouponPath = "coupon_lottery"
local RESVERSION = "2023-12-03-1"
local ITEM_TYPE_LOTTERY = {
	COIN = 1,
	PIGY = 2,
	JADES = 3,
}
local VERSION = "1.01"
local EVENT_ID = 1052
CouponLottery = ActivityBase_v2:newActivity("CouponLottery")
CouponLottery._updateReceiver = ActivityUpdateReceiver.new(EVENT_ID,function (  )
    CouponLottery.isReady()
end)

function CouponLottery:ctor()
    self.path = CouponPath
    self.ui = {}
    self.super.ctor(self)
    self._isShowAfterLiveEvents = false
end

function CouponLottery:onInit(data) --> = onLogin
    if data[EVENT_ID] and next(data[EVENT_ID].params) then
        local temp_data = data[EVENT_ID].params
        self:isReady()
        self:updateData(temp_data)
    end
end

function CouponLottery:isAvailable()
    return self:isReady() and self:getLeftTime() > 0
end

function CouponLottery:updateData(data)
    self.leftTime = data.coupon_lottery_left
    self.endTime = data.coupon_lottery_left + os.time()
    self.recvTime = os.time()
    self.checkwin = StoreControl:getInstance():isDoubleCheckWin()
    
    self._isShowAfterLiveEvents = false
end


function CouponLottery:isServerOpen(data)      ---活动是否开启
    -- return data.coupon_lottery_left and data.coupon_lottery_left > 0
    for i,v in pairs(data) do
        if i == EVENT_ID and v.version == VERSION then
            log.d("CouponLottery is open")
            return true
        end
    end
    return false
end



function CouponLottery:getLeftTime()
    if not self.leftTime then return 0 end
    local curLeftTime = self.leftTime - (os.time() - self.recvTime)
    if curLeftTime > 0 then
        return curLeftTime
    else
        return 0
    end
end

function CouponLottery:setUI( name,ui )
    self.ui[name] = ui
    ui:registerScriptHandler(function ( event )
        if event == "exit" then
            self:rmUI(name)
        end
    end)
end

function CouponLottery:rmUI( name )
    self.ui[name] = nil
end

function CouponLottery:isCheckWIn()
    return self.checkwin
end



function CouponLottery:onConsumeJade(data)
    if data.coupon_lottery_result then
        self.couponType = data.coupon_lottery_result[1]
        self.ratio = data.coupon_lottery_result[2]
        self.inboxId = data.inbox_id
        if bole.isValidNode(self.ui["buy"]) then
            self.ui["buy"]:startRollNew()
        end
    end
end

function CouponLottery:getType()
    return self.couponType
end

function CouponLottery:getRatio()
    return self.ratio
end

function CouponLottery:getInboxId()
    return self.inboxId
end

function CouponLottery:isReady()
    local isReady = bole.getResVerion(CouponPath.."/zzz") == RESVERSION
    if not isReady then
        bole.downloadZip(CouponPath , "res/".. CouponPath )
    end
    return isReady
end

function CouponLottery:showMainDialog(callback)
    local dialog  = nil
    if self:isAvailable() and self:getLeftTime() > 0 then 
        dialog = CouponLotteryMain.new(callback)
        dialog:show()
    else
        _= callback and callback()
    end
    
end

function CouponLottery:showMainDialogNew(callback)
    local dialog  = nil
    if self:isAvailable() and self:getLeftTime() > 0 then 
        dialog = CouponLotteryDialog.new(callback)
        dialog:show()
    else
        _= callback and callback()
    end
    
end


-- function CouponLottery:getMyNode(banner)
--     return bole.deepFind(banner, "CouponLottery")
-- end

-- function CouponLottery:onBannerCreate(banner)
--     local myNode = self:getMyNode(banner)
--     if myNode then
--         local picLevel1 = banner:getChildByName("level2")
--         local picLevel2 = banner:getChildByName("level1")
--         if self.group then
--             _ = picLevel1 and picLevel1:setVisible(self.group == 1)
--             _ = picLevel2 and picLevel2:setVisible(self.group == 2)
--         end

--     end
-- end

local function addSpine(parent, file, aniName, loop, pos, completeCallback,zOrder)
    aniName = aniName or "animation"
    loop = not (loop == false) -- nil=true
    pos = pos or bole.getNodeCenterPos(parent)
    local path = CouponPath .. "/spine/" .. file .. "/spine"
    local _, spine = bole.addSpineAnimation(parent, 0, path, pos, aniName, completeCallback, nil, nil, loop, loop)
    if zOrder then
        spine:setLocalZOrder(zOrder)
    end
    return spine
end

local function playBackgroundMusic(play)
	local volume = (play and 0) or 1
	if volume == 0 then
		originVolume = AudioEngine.getMusicVolume()
	else
		volume = originVolume
	end
	AudioEngine.setMusicVolume(volume)
end

local function loadMusic(name , path)
	path = path or CouponPath.."/sounds/"
	bole.loadMusic(name, path)
end

local function preloadMusic()
	loadMusic("cl_coupon")
	loadMusic("cl_reward")
end

local function playMusic(play, name, loop, path)
	path = path or CouponPath.."/sounds/"
	if not loop then loop = false end
	if play then
		bole.playMusic (name, nil, loop, path)
	else
		bole.stopMusic (name, path)
	end
end

---------------------------------
---CouponLottery Main 
---------------------------------
CouponLotteryMain = class("CouponLotteryMain" , CCSNode)

function CouponLotteryMain:ctor(callback)
    self.callback = callback
    self.ctl = ActivityControl_v2:getInstance():getActivityIns("CouponLottery")
    self.super.ctor(self , CouponPath.."/csd/node_yiji.csb")
    self.timeLine = cc.CSLoader:createTimeline(self.csb)
    self.node:runAction(self.timeLine)
    bole.addKeyboardEvent(self, function ()
        self:hide()
    end)
end

function CouponLotteryMain:hide()
    bole.popExitWin(self, self, nil, true, self.callback)
end

function CouponLotteryMain:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addPop(self, 3)
    bole.addMaskLayer(self)
    self:runTimeLine(0)
    local btnClose = self.root:getChildByName("btn_close")
    local btnPlay = self.root:getChildByName("btn_lets")
    btnClose:setTouchEnabled(false)
    btnPlay:setTouchEnabled(false)
    bole.popWin(self, nil, nil, function ()
        self:runTimeLine(0, 65, false)
        bole.laterCall(1,self.node:getChildByName("root"),function ( )
            btnClose:setTouchEnabled(true)
            btnPlay:setTouchEnabled(true)
            self:runTimeLine(65, 165, true)
        end)
    end)
end


function CouponLotteryMain:loadControls()
    self.root = self.node:getChildByName("root")
    local btnClose = self.root:getChildByName("btn_close")
    self:addTouchEvent(btnClose, function ()
        btnClose:setTouchEnabled(false)
        bole.playMusic("game2")
        self:hide()
    end)
    local btnPlay = self.root:getChildByName("btn_lets")
    self:addTouchEvent(btnPlay, function ()
        btnPlay:setTouchEnabled(false)
        bole.playMusic("game2")
        CouponLotteryDialog.new():show()
        self:hide()
    end)
    self:countDown()
    self:addEffect()
end

function CouponLotteryMain:addEffect()
    local logo = self.root:getChildByName("logo")
    local s = addSpine(logo,"logo_effect","logo",true)
    logo:setLocalZOrder(1)
    -- s:setScale(0.8)
    logo:setBlendFunc(gl.ZERO, gl.ONE)
    local image = self.root:getChildByName("zhu"):getChildByName("cx1")
    addSpine(image,"logo_effect","coupon",true)
    -- addSpine(self.root:getChildByName("tu"),"gej_ye")
end

function CouponLotteryMain:countDown()   
    local lblLeftTime = self.root:getChildByName("daojishi"):getChildByName("text_naozhong")
    bole.configCountDownLabel(lblLeftTime,function()
        return self.ctl:getLeftTime()
    end,function ()
        lblLeftTime:stopAllActions()
        self:hide()
    end)
end
---------------------------------
---CouponLottery Dialog 抽奖
---------------------------------




CouponLotteryDialog = class("CouponLotteryDialog" , CCSNode)

function CouponLotteryDialog:ctor(callback)
    self.callback = callback
    preloadMusic()
    self.ctl = ActivityControl_v2:getInstance():getActivityIns("CouponLottery")
    self.ctl:setUI("buy",self)
    self.super.ctor(self , CouponPath.."/csd/node_erji.csb")
    self.timeLine = cc.CSLoader:createTimeline(self.csb)
    self.node:runAction(self.timeLine)
    bole.addKeyboardEvent(self, function ()
        self:hide()
    end)
end

--控制显示info

function CouponLotteryDialog:hide()
    bole.popExitWin(self, self, nil, true, self.callback)
end

function CouponLotteryDialog:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addPop(self, 3)
    bole.addMaskLayer(self)
    self:runTimeLine(0)
    bole.popWin(self, nil, nil, nil)
end


function CouponLotteryDialog:loadControls()
    self.rewardPart = {}
    self.order = {1,4,5,6,7,8,9,10,11,12,13,14,3,2}     ---csd order
    self.root = self.node:getChildByName("root")
    local btnClose = self.root:getChildByName("btn_btn_close")
    local btnPlay = self.root:getChildByName("btn_shuzi")
    local btnEnd = self.root:getChildByName("btn_lets")
    local logo = self.root:getChildByName("logo")
    local s = addSpine(logo,"logo_effect","logo",true)
    logo:setLocalZOrder(1)
    logo:setBlendFunc(gl.ZERO, gl.ONE)

    btnEnd:setVisible(false)
    self:addTouchEvent(btnClose, function ()
        btnClose:setTouchEnabled(false)
        bole.playMusic("game2")
        self:hide()
    end)
    self.reward = self.root:getChildByName('jiangli')
    -- bole.addMaskLayer(self.reward, nil, 175)
    for i = 1,14 do
        local  rewardIcon = self.reward:getChildByName("jiangli"..tostring(i))
        table.insert( self.rewardPart, rewardIcon)
        rewardIcon:getChildByName("an"):setVisible(false)
    end
    self:initReward()
    
    self:addTouchEvent(btnPlay, function ()
        if self:canBuy() then
            for i = 1,14 do
                self:changeState(i,false)
            end
            btnClose:setVisible(false)
            btnPlay:setTouchEnabled(false)
            bole.playMusic("game2")
            bole.laterCall(0.2,function ()
                self:consumeJades()
            end)
        end
    end)

    -- local logo = self.root:getChildByName("logo")
    -- bole.addClickEvent(logo,function ( )
    --     self:startRoll()
    -- end)
    self:countDown()
end

function CouponLotteryDialog:countDown()
    -- local lastServerLabel = cc.Label:create()
    -- self.root:addChild(lastServerLabel)
    -- lastServerLabel:setVisible(false)
    -- bole.configCountDownLabel(lastServerLabel,function()
    --     return self.ctl:getLeftTime()
    -- end,function ()
    --     self:hide()
    -- end)
    self.root:getChildByName("Text_1"):setVisible(false)
    bole.configCountDownLabel(self.root:getChildByName("Text_1"),function()
        return self.ctl:getLeftTime()
    end,function ()
        self:hide()
    end)
end

---------------奖励初始化
function CouponLotteryDialog:initReward()
    for i = 1,14 do
        self.rewardPart[i]:getChildByName("liang"):getChildByName("pigy"):setVisible(false)
        self.rewardPart[i]:getChildByName("liang"):getChildByName("jades"):setVisible(false)
        self.rewardPart[i]:getChildByName("liang"):getChildByName("coins"):setVisible(false)
        -- local box = self.rewardPart[i]:getChildByName("liang"):getChildByName("zhao")
        self.rewardPart[i]:getChildByName("an"):getChildByName("pigy"):setVisible(false)
        self.rewardPart[i]:getChildByName("an"):getChildByName("jades"):setVisible(false)
        self.rewardPart[i]:getChildByName("an"):getChildByName("coins"):setVisible(false)
    end
    self:setReward(1,true,"coins","120%")
    self:setReward(4,true,"pigy","50%")
    self:setReward(5,true,"coins","200%")
    self:setReward(6,true,"coins","80%")
    self:setReward(7,true,"pigy","200%")
    self:setReward(8,true,"coins","30%")
    self:setReward(9,true,"jades","20%")
    self:setReward(10,true,"coins","80%")
    self:setReward(11,true,"pigy","100%")
    self:setReward(12,true,"coins","200%")
    self:setReward(13,true,"coins","50%")
    self:setReward(14,true,"pigy","200%")
    self:setReward(3,true,"coins","80%")
    self:setReward(2,true,"jades","20%")
    for i = 1,14 do
        self:changeState(i,true)
    end
end

function CouponLotteryDialog:setReward(index,bright,coupon,ratio)
    local type = "liang"
    local ratioText = ""
    if not bright then
        type = "an"
    end
    if coupon == "pigy" then
        ratioText = "text_hong"
    elseif coupon == "jades" then
        ratioText = "text_lv"
    elseif coupon == "coins" then
        ratioText = "text_huang"
    end
    self.rewardPart[index]:getChildByName("liang"):getChildByName(coupon):setVisible(true)
    self.rewardPart[index]:getChildByName("liang"):getChildByName(coupon):getChildByName(ratioText):setString(ratio)
    self.rewardPart[index]:getChildByName("an"):getChildByName(coupon):setVisible(true)
    self.rewardPart[index]:getChildByName("an"):getChildByName(coupon):getChildByName(ratioText):setString(ratio)
end

function CouponLotteryDialog:changeState(index,bright,callback)
    if bright then
        self.rewardPart[index]:getChildByName("liang"):setVisible(true)
        -- local addBirght = self.rewardPart[index]:getChildByName("liang"):getChildByName("zhao"):getChildByName("zhaoinside")
        -- addBirght:setBlendFunc(gl.ONE, gl.ONE)
        self.rewardPart[index]:getChildByName("an"):setVisible(false)
    else
        self.rewardPart[index]:getChildByName("liang"):setVisible(false)
        self.rewardPart[index]:getChildByName("an"):setVisible(true)
    end
    _ = callback and callback()
end

function CouponLotteryDialog:biggerBox(index)
    local box = self.rewardPart[index]:getChildByName("liang")
    box:runAction(cc.RepeatForever:create(
        cc.Sequence:create(
            cc.EaseSineInOut:create(cc.ScaleTo:create(5/60, 1.1))
        )
    ))
end

function CouponLotteryDialog:findEndIndex()
    local rewardType = self.ctl:getType()
    local rewardRatio = self.ctl:getRatio()
    if rewardType == 1 then
        if rewardRatio == 120 then
            return {1}
        elseif rewardRatio == 200 then
            return {3,10}
        elseif rewardRatio == 80 then
            return {4,8,13}
        elseif rewardRatio == 30 then
            return {6}
        elseif rewardRatio == 50 then
            return {11}
        end
    elseif rewardType == 2  then
        if rewardRatio == 50 then
            return {2}
        elseif rewardRatio == 200 then
            return {5,9,12}
        elseif rewardRatio == 100 then
            return {9}
        end
    elseif rewardType == 3 then
        return {7,14}
    end
end

function CouponLotteryDialog:startRollNew()
    self.index = 1
    local ratio = {8,8,10,10}
    math.randomseed(os.time())
    local endIndex = self:findEndIndex()
    local indexCal = 0
    if # endIndex == 1  then
        indexCal = endIndex[1]
    elseif # endIndex == 2  then
        local i = math.random(1,2)
        indexCal = endIndex[i]
    elseif # endIndex == 3 then
        local i = math.random(1,3)
        indexCal = endIndex[i]
    end
    indexCal = 14  + indexCal
    local step1 = indexCal - 10
    local step2 = 2
    local step3 = 5
    local step4 = 3
    local speeedList = {step1,step1+step2,step1+step2+step3,step1+step2+step3+step4 }
    

    local baseDt = 0.016
    local period = 3 * baseDt    -- time 
    local countTime = 0
    local flag = true
    local speed = 0
    local function updateFrame(dt)
        if self.index <= speeedList[1] then
            speed = ratio[1]
        elseif self.index > speeedList[1] and self.index <= speeedList[2] then
            speed = ratio[2]
        elseif self.index > speeedList[2] and self.index <= speeedList[3] then
            speed = ratio[3]
        elseif self.index > speeedList[3] and self.index <= speeedList[4] then
            speed = ratio[4]
        end
       
        countTime = countTime + dt

        if countTime > period then
            if flag then
                period = period + speed * baseDt * 2
                self:changeState(self.order[ (self.index-1) % 14 + 1],true)
                self:biggerBox(self.order[ (self.index-1) % 14 + 1])
                playMusic(true,"cl_coupon",false)
                flag = false
                if self.index == indexCal then
                    self:unscheduleUpdate()
                    bole.laterCall(0.5 , function()
                        self:onRollOver()
                    end)
                end
            else
                period = period + speed * baseDt
                self:changeState(self.order[ (self.index-1) % 14 + 1],false)
                self.index = self.index + 1
                flag = true
            end
        end
       
    end
    self:scheduleUpdateWithPriorityLua(updateFrame , 0)
end

function CouponLotteryDialog:onRollOver()
    local rewardType = self.ctl:getType()
    local rewardRatio = self.ctl:getRatio()
    self:hide()
    playMusic(true,"cl_reward",false)
    CouponLotteryReward.new(rewardType,rewardRatio,nil):show()
end

function CouponLotteryDialog:canBuy()
    local needJades =  JadeControl:getInstance():getJades()
    if needJades < 198 then
        JadeControl:getInstance():showPurchaseDialog(needJades)
        return false
    else 
        return true
    end
end

function CouponLotteryDialog:consumeJades()
    JadeControl:getInstance():sendConsumeCMD(CONSUME_JADE_TYPE.COUPON_LOTTERY,{})
end


----------------- getRewardPart

CouponLotteryReward = class("CouponLotteryReward" , CCSNode)
function CouponLotteryReward:ctor(rewardType,rewardRatio,callback)
    self.callback = callback
    self.type = rewardType
    self.ratio = rewardRatio
    self.ctl = ActivityControl_v2:getInstance():getActivityIns("CouponLottery")
    self.ctl:setUI("reward",self)
    self.super.ctor(self , CouponPath.."/csd/node_huojiang.csb")
    self.timeLine = cc.CSLoader:createTimeline(self.csb)
    self.node:runAction(self.timeLine)
    bole.addKeyboardEvent(self, function ()
        self:hide()
    end)
end

--控制显示info

function CouponLotteryReward:hide()
    bole.popExitWin(self, self, nil, true, self.callback)
end

function CouponLotteryReward:loadControls()
    self.inboxId = self.ctl:getInboxId()
    self.root = self.node:getChildByName("root")
    self.reward = self.root:getChildByName("ProjectNode_1")
    self.reward:getChildByName("an"):setVisible(false)
    self.reward:getChildByName("liang"):getChildByName("pigy"):setVisible(false)
    self.reward:getChildByName("liang"):getChildByName("coins"):setVisible(false)
    self.reward:getChildByName("liang"):getChildByName("jades"):setVisible(false)
    if self.type == 1 then
        self.reward:getChildByName("liang"):getChildByName("coins"):setVisible(true)
        self.reward:getChildByName("liang"):getChildByName("coins"):getChildByName("text_huang"):setString(tostring(self.ratio).."%")
    elseif self.type == 2 then
        self.reward:getChildByName("liang"):getChildByName("pigy"):setVisible(true)
        self.reward:getChildByName("liang"):getChildByName("pigy"):getChildByName("text_hong"):setString(tostring(self.ratio).."%")
    elseif self.type == 3 then
        self.reward:getChildByName("liang"):getChildByName("jades"):setVisible(true)
        self.reward:getChildByName("liang"):getChildByName("jades"):getChildByName("text_lv"):setString(tostring(self.ratio).."%")
    end
    ---感恩节版
    -- self.reward:getChildByName("liang"):getChildByName("zhao"):setVisible(false)
    local btnRedeem = self.root:getChildByName("btn_redeem")
    self:addTouchEvent(btnRedeem, function ()
        btnRedeem:setTouchEnabled(false)
        bole.playMusic("game2")
        self:toInbox()
        self:hide()
    end)
    local btnLater = self.root:getChildByName("btn_later")
    bole.addClickEvent(btnLater,function ( )
        self:hide()
    end)
    self:addEffect()
end

function CouponLotteryReward:toInbox()
    if  self.inboxId then
        if self.type == ITEM_TYPE_LOTTERY.COIN then
            if StoreControl_v2:getInstance():isUseNewStore() then
                local inboxID = self.ctl:getInboxId() -- 获取 inbox ID
                local notification = Notification.new("store_show_coupon", {inboxID = inboxID}) -- 创建通知
                NotificationCenter:getInstance():notify(notification) -- 发送通知
                return 
            end
            local dialog = StoreControl:getInstance():getStoreDialog(nil, {ratio = self.ratio , index = self.inboxId , server = true , type = COUPON_ITEM_TYPE.COIN})
            if dialog then
                dialog:show()
            end
        elseif self.type == ITEM_TYPE_LOTTERY.JADES then
            if StoreControl_v2:getInstance():isUseNewStore() then
                local inboxID = self.ctl:getInboxId() -- 获取 inbox ID
                local notification = Notification.new("store_show_coupon", {inboxID = inboxID}) -- 创建通知
                NotificationCenter:getInstance():notify(notification) -- 发送通知
                return 
            end
            local dialog = StoreControl:getInstance():getStoreDialog(nil, {ratio = self.ratio , index = self.inboxId , server = true , type = COUPON_ITEM_TYPE.JADE})
            if dialog then
                dialog:show(STORE_STOP_POS.JADE)
            end
        elseif self.type == ITEM_TYPE_LOTTERY.PIGY then
            local params = {
                type = 1,
                inboxId = self.inboxId,
                radio = self.ratio
            }
            if OinkyControl_v2:isInAbTest() then
                OinkyControl_v2:getInstance():showMainDialog(params)
            end
        end
    end  
end

function CouponLotteryReward:show()
    self.node:setScale(0.625)
    self.node:setPosition(cc.p(400, 225+bole.winFixY))
    bole.scene:addPop(self, 3)
    bole.addMaskLayer(self)
    self:runTimeLine(0)
    bole.popWin(self, nil, nil, function ()
        self:runTimeLine(0, 65, false)
    end)
end

function CouponLotteryReward:addEffect()
    local image = self.root:getChildByName("ProjectNode_1")
    -- addSpine(image,"guang_effect",nil,true,nil,nil,-1)
    addSpine(image,"christmas_prize",nil,true,nil,nil,-1)
    local title = self.root:getChildByName("biaoti")
    addSpine(title,"title_effect")

    -- addSpine(self.root:getChildByName("bj1"),"gej_ye")
    -- local yezi = {"yezi_2","yezi_3","yezi_4","yezi_5"}
    -- for i = 1,#yezi do
    --     self.root:getChildByName(yezi[i]):setVisible(false)
    -- end
end