// _RosterWindow_EOArchive_English.java
// Generated by EnterpriseObjects palette at Tuesday, 16 August 2005 13:00:02 Europe/London

import com.webobjects.eoapplication.*;
import com.webobjects.eocontrol.*;
import com.webobjects.eointerface.*;
import com.webobjects.eointerface.swing.*;
import com.webobjects.eointerface.swing.EOTable._EOTableColumn;
import com.webobjects.foundation.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import javax.swing.text.*;

public class _RosterWindow_EOArchive_English extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOFrame _eoFrame0;
    com.webobjects.eointerface.swing.EOTable _nsOutlineView0;
    com.webobjects.eointerface.swing.EOTable._EOTableColumn _eoTableColumn0;
    javax.swing.JComboBox _popup0;
    javax.swing.JPanel _nsView0;

    public _RosterWindow_EOArchive_English(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();


        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "presenceBox")) != null)) {
            _popup0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (javax.swing.JComboBox)replacement;
            _replacedObjects.setObjectForKey(replacement, "_popup0");
        } else {
            _popup0 = (javax.swing.JComboBox)_registered(new javax.swing.JComboBox(), "NSPopUpButton");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "column")) != null)) {
            _eoTableColumn0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTable._EOTableColumn)replacement;
            _replacedObjects.setObjectForKey(replacement, "_eoTableColumn0");
        } else {
            _eoTableColumn0 = (com.webobjects.eointerface.swing.EOTable._EOTableColumn)_registered(new com.webobjects.eointerface.swing.EOTable._EOTableColumn(), "NSTableColumn1");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view")) != null)) {
            _nsOutlineView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTable)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsOutlineView0");
        } else {
            _nsOutlineView0 = (com.webobjects.eointerface.swing.EOTable)_registered(new com.webobjects.eointerface.swing.EOTable(), "NSTableView");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "window")) != null)) {
            _eoFrame0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOFrame)replacement;
            _replacedObjects.setObjectForKey(replacement, "_eoFrame0");
        } else {
            _eoFrame0 = (com.webobjects.eointerface.swing.EOFrame)_registered(new com.webobjects.eointerface.swing.EOFrame(), "Window");
        }

        _nsView0 = (JPanel)_eoFrame0.getContentPane();
    }

    protected void _awaken() {
        super._awaken();
        _nsOutlineView0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "click", _nsOutlineView0), ""));

        if (_replacedObjects.objectForKey("_nsOutlineView0") == null) {
            _connect(_nsOutlineView0, _owner(), "delegate");
        }

        if (_replacedObjects.objectForKey("_nsOutlineView0") == null) {
            _connect(_nsOutlineView0, _owner(), "dataSource");
        }

        _popup0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changePresence", _popup0), ""));

        if (_replacedObjects.objectForKey("_popup0") == null) {
            _popup0.setModel(new javax.swing.DefaultComboBoxModel());
            _popup0.addItem("Free For Chat");
            _popup0.addItem("Online");
            _popup0.addItem("Away");
            _popup0.addItem("Extended Away");
            _popup0.addItem("Do Not Disturb");
            _popup0.addItem("");
            _popup0.addItem("Offline");
            _popup0.addItem("");
            _popup0.addItem("Custom\u2026");
        }

        if (_replacedObjects.objectForKey("_popup0") == null) {
            _connect(_owner(), _popup0, "presenceBox");
        }

        if (_replacedObjects.objectForKey("_eoFrame0") == null) {
            _connect(_owner(), _eoFrame0, "window");
        }

        if (_replacedObjects.objectForKey("_nsOutlineView0") == null) {
            _connect(_owner(), _nsOutlineView0, "view");
        }

        if (_replacedObjects.objectForKey("_eoTableColumn0") == null) {
            _connect(_owner(), _eoTableColumn0, "column");
        }
    }

    protected void _init() {
        super._init();

        if (_replacedObjects.objectForKey("_popup0") == null) {
            _setFontForComponent(_popup0, "Lucida Grande", 11, Font.PLAIN);
        }

        if (_replacedObjects.objectForKey("_eoTableColumn0") == null) {
            _eoTableColumn0.setMinWidth(8);
            _eoTableColumn0.setMaxWidth(10000);
            _eoTableColumn0.setPreferredWidth(116);
            _eoTableColumn0.setWidth(116);
            _eoTableColumn0.setResizable(false);
            _eoTableColumn0.setHeaderValue("");
            if ((_eoTableColumn0.getHeaderRenderer() != null)) {
            	((DefaultTableCellRenderer)(_eoTableColumn0.getHeaderRenderer())).setHorizontalAlignment(javax.swing.JTextField.LEFT);
            }
        }

        if (_replacedObjects.objectForKey("_nsOutlineView0") == null) {
            _nsOutlineView0.table().addColumn(_eoTableColumn0);
            _setFontForComponent(_nsOutlineView0.table().getTableHeader(), "Lucida Grande", 11, Font.PLAIN);
            _nsOutlineView0.table().setRowHeight(20);
        }

        if (!(_nsView0.getLayout() instanceof EOViewLayout)) { _nsView0.setLayout(new EOViewLayout()); }
        _nsOutlineView0.setSize(132, 51);
        _nsOutlineView0.setLocation(-7, 14);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsOutlineView0, EOViewLayout.WidthSizable | EOViewLayout.HeightSizable);
        _nsView0.add(_nsOutlineView0);
        _popup0.setSize(91, 22);
        _popup0.setLocation(15, -7);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_popup0, EOViewLayout.WidthSizable | EOViewLayout.MaxYMargin);
        _nsView0.add(_popup0);

        if (_replacedObjects.objectForKey("_eoFrame0") == null) {
            _nsView0.setSize(118, 79);
            _eoFrame0.setTitle("Roster");
            _eoFrame0.setLocation(331, 811);
            _eoFrame0.setSize(118, 79);
        }
    }
}