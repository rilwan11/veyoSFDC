trigger lead_trigger on Lead (after insert) {
    lead_handler.convertLeads(trigger.new);
}