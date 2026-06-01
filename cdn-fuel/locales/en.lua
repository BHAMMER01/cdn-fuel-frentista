local Translations = {
    -- Fuel
    set_fuel_debug = "Combustível definido para:",
    cancelled = "Cancelado.",
    not_enough_money = "Dinheiro insuficiente!",
    not_enough_money_in_bank = "Saldo bancário insuficiente!",
    not_enough_money_in_cash = "Dinheiro em mãos insuficiente!",
    more_than_zero = "Informe mais de 0L!",
    emergency_shutoff_active = "As bombas estão desligadas pela emergência.",
    nozzle_cannot_reach = "O bico não alcança tão longe!",
    station_no_fuel = "Este posto está sem combustível!",
    station_not_enough_fuel = "O posto não tem esse volume!",
    show_input_key_special = "Pressione [G] perto do veículo para abastecer!",
    tank_cannot_fit = "Não cabe tudo no tanque!",
    tank_already_full = "O veículo já está cheio!",
    need_electric_charger = "Use um carregador elétrico!",
    cannot_refuel_inside = "Você não pode abastecer dentro do veículo!",
    self_refuel = "Abastecer eu mesmo",
    call_attendant = "Chamar frentista",
    attendant_busy = "O frentista já está atendendo.",
    attendant_unavailable = "Frentista indisponível aqui.",
    attendant_no_vehicle = "Nenhum veículo perto da bomba.",
    attendant_vehicle_too_far = "Você parou muito longe da bomba.",
    attendant_payment_failed = "Pagamento recusado.",
    attendant_started = "Frentista a caminho.",
    attendant_finished = "Abastecimento concluído.",
    attendant_cancelled = "Atendimento cancelado.",
    attendant_input_header = "Frentista",
    attendant_input_fuel_price = "Preço por litro",
    attendant_input_current_fuel = "Tanque atual",
    attendant_input_max_fuel = "Máximo disponível",
    attendant_input_total = "Total para encher",
    attendant_input_amount = "Litros para abastecer",
    attendant_input_payment = "Forma de pagamento",
    attendant_pay_cash = "Pagar em dinheiro",
    attendant_pay_bank = "Pagar pelo banco",
    attendant_refueling = "Frentista abastecendo...",
    attendant_returning = "Frentista devolvendo o bico.",

    -- 2.1.2 -- Reserves Pickup ---
    fuel_order_ready = "Pedido pronto para retirada! Veja o GPS.",
    draw_text_fuel_dropoff = "[E] Entregar caminhão",
    fuel_pickup_success = "Reservas abastecidas para: %sL",
    fuel_pickup_failed = "A Ron Oil entregou o combustível no seu posto!",
    trailer_too_far = "O reboque não está preso ou está longe demais!",

    -- 2.1.0
    no_nozzle = "Você está sem o bico!",
    vehicle_is_damaged = "Veículo danificado demais para abastecer!",
    vehicle_too_far = "Você está longe demais deste veículo!",
    inside_vehicle = "Você não pode abastecer dentro do veículo!",
    you_are_discount_eligible = "Entre em serviço para ganhar "..Config.EmergencyServicesDiscount['discount'].."% de desconto!",
    no_fuel = "Sem combustível.",

    -- Electric
    electric_more_than_zero = "Carregue mais de 0KW!",
    electric_vehicle_not_electric = "Este veículo não é elétrico!",
    electric_no_nozzle = "Você está sem o conector elétrico!",

    -- Phone --
    electric_phone_header = "Carregador elétrico",
    electric_phone_notification = "Total da recarga: $",
    fuel_phone_header = "Posto",
    phone_notification = "Total: $",
    phone_refund_payment_label = "Reembolso no posto!",

    -- Stations
    station_per_liter = " / litro!",
    station_already_owned = "Este local já tem dono!",
    station_cannot_sell = "Você não pode vender este local!",
    station_sold_success = "Local vendido com sucesso!",
    station_not_owner = "Você não é dono deste local!",
    station_amount_invalid = "Valor inválido!",
    station_more_than_one = "Compre mais de 1L!",
    station_price_too_high = "Preço alto demais!",
    station_price_too_low = "Preço baixo demais!",
    station_name_invalid = "Nome inválido!",
    station_name_too_long = "Nome não pode passar de "..Config.NameChangeMaxChar.." caracteres.",
    station_name_too_short = "Nome deve ter mais de "..Config.NameChangeMinChar.." caracteres.",
    station_withdraw_too_much = "O posto não tem esse saldo!",
    station_withdraw_too_little = "Retire pelo menos $1!",
    station_success_withdrew_1 = "Retirado $",
    station_success_withdrew_2 = " do caixa do posto!", -- Leave the space @ the front!
    station_deposit_too_much = "Você não tem esse valor!",
    station_deposit_too_little = "Deposite pelo menos $1!",
    station_success_deposit_1 = "Depositado $",
    station_success_deposit_2 = " no caixa do posto!", -- Leave the space @ the front!
    station_cannot_afford_deposit = "Você não pode depositar $",
    station_shutoff_success = "Estado das bombas alterado!",
    station_fuel_price_success = "Preço alterado para $",
    station_reserve_cannot_fit = "As reservas não comportam isso!",
    station_reserves_over_max =  "Esse volume passa do limite de "..Config.MaxFuelReserves.." litros.",
    station_name_change_success = "Nome alterado para: ", -- Leave the space @ the end!
    station_purchased_location_payment_label = "Posto comprado: ",
    station_sold_location_payment_label = "Posto vendido: ",
    station_withdraw_payment_label = "Saque do posto. Local: ",
    station_deposit_payment_label = "Depósito no posto. Local: ",

    -- All Progress Bars
    prog_refueling_vehicle = "Abastecendo veículo...",
    prog_electric_charging = "Carregando...",
    prog_jerry_can_refuel = "Abastecendo galão...",
    prog_syphoning = "Sifonando combustível...",

    -- Menus
    menu_header_cash = "Dinheiro",
    menu_header_bank = "Banco",
    menu_header_close = "Cancelar",
    menu_pay_with_cash = "Pagar em dinheiro.  \nVocê tem: $",
    menu_pay_with_bank = "Pagar pelo banco.",
    menu_refuel_header = "Posto",
    menu_refuel_accept = "Comprar combustível.",
    menu_refuel_cancel = "Não quero abastecer.",
    menu_pay_label_1 = "Combustível @ ",
    menu_pay_label_2 = " / L",
    menu_header_jerry_can = "Galão",
    menu_header_refuel_jerry_can = "Abastecer galão",
    menu_header_refuel_vehicle = "Abastecer veículo",

    menu_electric_cancel = "Não quero carregar agora.",
    menu_electric_header = "Carregador elétrico",
    menu_electric_accept = "Pagar a recarga.",
    menu_electric_payment_label_1 = "Energia @ ",
    menu_electric_payment_label_2 = " / KW",

    -- Station Menus
    menu_ped_manage_location_header = "Gerenciar local",
    menu_ped_manage_location_footer = "Se for dono, gerencie este local.",

    menu_ped_purchase_location_header = "Comprar local",
    menu_ped_purchase_location_footer = "Se estiver livre, você pode comprar.",

    menu_ped_emergency_shutoff_header = "Alternar emergência",
    menu_ped_emergency_shutoff_footer = "Desliga as bombas em emergência.   \n Bombas agora: ",

    menu_ped_close_header = "Encerrar conversa",
    menu_ped_close_footer = "Não quero falar sobre isso.",

    menu_station_reserves_header = "Comprar reservas para ",
    menu_station_reserves_purchase_header = "Comprar reservas por: $",
    menu_station_reserves_purchase_footer = "Comprar reservas por $",
    menu_station_reserves_cancel_footer = "Não quero comprar reservas!",

    menu_purchase_station_header_1 = "Total com taxas: $",
    menu_purchase_station_header_2 = " com taxas.",
    menu_purchase_station_confirm_header = "Confirmar",
    menu_purchase_station_confirm_footer = "Comprar este local por $",
    menu_purchase_station_cancel_footer = "Não quero comprar. Preço absurdo!",

    menu_sell_station_header = "Vender ",
    menu_sell_station_header_accept = "Vender posto",
    menu_sell_station_footer_accept = "Vender este local por $",
    menu_sell_station_footer_close = "Não tenho mais nada para tratar.",

    menu_manage_header = "Gestão de ",
    menu_manage_reserves_header = "Reservas  \n",
    menu_manage_reserves_footer_1 =  " litros de ",
    menu_manage_reserves_footer_2 =  " litros  \nCompre mais reservas abaixo!",

    menu_manage_purchase_reserves_header = "Comprar mais reservas",
    menu_manage_purchase_reserves_footer = "Comprar reservas por $",
    menu_manage_purchase_reserves_footer_2 = " / L!",

    menu_alter_fuel_price_header = "Alterar preço",
    menu_alter_fuel_price_footer_1 = "Mudar o preço do combustível.  \nAtual: $",

    menu_manage_company_funds_header = "Caixa do posto",
    menu_manage_company_funds_footer = "Gerenciar saldo deste local.",
    menu_manage_company_funds_header_2 = "Caixa de ",
    menu_manage_company_funds_withdraw_header = "Retirar saldo",
    menu_manage_company_funds_withdraw_footer = "Retirar dinheiro da conta do posto.",
    menu_manage_company_funds_deposit_header = "Depositar saldo",
    menu_manage_company_funds_deposit_footer = "Depositar dinheiro na conta do posto.",
    menu_manage_company_funds_return_header = "Voltar",
    menu_manage_company_funds_return_footer = "Quero tratar de outra coisa.",

    menu_manage_change_name_header = "Alterar nome",
    menu_manage_change_name_footer = "Mudar o nome deste local.",

    menu_manage_sell_station_footer = "Vender seu posto por $",

    menu_manage_close = "Não tenho mais nada para tratar!",

    -- Jerry Can Menus
    menu_jerry_can_purchase_header = "Comprar galão por $",
    menu_jerry_can_footer_full_gas = "Galão cheio!",
    menu_jerry_can_footer_refuel_gas = "Abastecer o galão.",
    menu_jerry_can_footer_use_gas = "Usar no veículo.",
    menu_jerry_can_footer_no_gas = "O galão está vazio!",
    menu_jerry_can_footer_close = "Não quero mais um galão.",
    menu_jerry_can_close = "Não quero usar isso agora.",

    -- Syphon Kit Menus
    menu_syphon_kit_full = "Kit sifão cheio! Cabe só " .. Config.SyphonKitCap .. "L!",
    menu_syphon_vehicle_empty = "O tanque deste veículo está vazio.",
    menu_syphon_allowed = "Sifonar combustível.",
    menu_syphon_refuel = "Usar combustível sifonado no veículo.",
    menu_syphon_empty = "Usar combustível sifonado no veículo.",
    menu_syphon_cancel = "Não quero usar isso agora.",
    menu_syphon_header = "Sifão",
    menu_syphon_refuel_header = "Abastecer",

    -- Input --
    input_select_refuel_header = "Escolha quantos litros abastecer.",
    input_refuel_submit = "Abastecer veículo",
    input_refuel_jerrycan_submit = "Abastecer galão",
    input_max_fuel_footer_1 = "Até ",
    input_max_fuel_footer_2 = "L de combustível.",
    input_insert_nozzle = "Inserir bico", -- Used for Target as well!

    input_purchase_reserves_header_1 = "Comprar reservas  \nPreço atual: $",
    input_purchase_reserves_header_2 = Config.FuelReservesPrice .. " / litro  \nReservas atuais: ",
    input_purchase_reserves_header_3 = " litros  \nCusto para encher: $",
    input_purchase_reserves_submit_text = "Comprar reservas",
    input_purchase_reserves_text = 'Quantidade de reservas.',

    input_alter_fuel_price_header_1 = "Alterar preço   \nPreço atual: $",
    input_alter_fuel_price_header_2 = " / litro",
    input_alter_fuel_price_submit_text = "Alterar preço",

    input_change_name_header_1 = "Alterar nome de ",
    input_change_name_header_2 = ".",
    input_change_name_submit_text = "Salvar nome",
    input_change_name_text = "Novo nome...",

    input_withdraw_funds_header = "Retirar saldo  \nSaldo atual: $",
    input_withdraw_submit_text = "Retirar",
    input_withdraw_text = "Valor para retirar",

    input_deposit_funds_header = "Depositar saldo  \nSaldo atual: $",
    input_deposit_submit_text = "Depositar",
    input_deposit_text = "Valor para depositar",

    -- Target
    grab_electric_nozzle = "Pegar conector elétrico",
    insert_electric_nozzle = "Inserir conector elétrico",
    grab_nozzle = "Pegar bico",
    return_nozzle = "Devolver bico",
    grab_special_nozzle = "Pegar bico especial",
    return_special_nozzle = "Devolver bico especial",
    buy_jerrycan = "Comprar galão",
    station_talk_to_ped = "Falar sobre o posto",

    -- Jerry Can
    jerry_can_full = "Galão cheio!",
    jerry_can_refuel = "Abastecer galão.",
    jerry_can_not_enough_fuel = "O galão não tem esse volume!",
    jerry_can_not_fit_fuel = "Não cabe tudo no galão!",
    jerry_can_success = "Galão abastecido!",
    jerry_can_success_vehicle = "Veículo abastecido com o galão!",
    jerry_can_payment_label = "Galão comprado.",

    -- Syphoning
    syphon_success = "Combustível sifonado!",
    syphon_success_vehicle = "Veículo abastecido com o kit sifão!",
    syphon_electric_vehicle = "Este veículo é elétrico!",
    syphon_no_syphon_kit = "Você precisa de um kit sifão.",
    syphon_inside_vehicle = "Você não pode sifonar dentro do veículo!",
    syphon_more_than_zero = "Sifone mais de 0L!",
    syphon_kit_cannot_fit_1 = "Não cabe tudo no kit. Cabe apenas: ",
    syphon_kit_cannot_fit_2 = " litros.",
    syphon_not_enough_gas = "Você não tem combustível suficiente!",
    syphon_dispatch_string = "(10-90) - Roubo de combustível",
}

Lang = Locale:new({phrases = Translations, warnOnMissing = false})

if Config.Core ~= "qb-core" or Config.Core ~= "qbx-core" then
    function FetchLocale(t)
        if Translations[t] then
            return Translations[t]
        end
    end
end
