trigger TR_Account on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new MetadataTriggerHandler().run();
}